import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/errors/failure_exception.dart';
import 'package:eventhub/core/firebase/firebase_providers.dart';
import 'package:eventhub/core/firebase/firestore_paths.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/core/utils/app_logger.dart';
import 'package:eventhub/features/auth/domain/entities/app_user.dart';
import 'package:eventhub/features/events/domain/entities/event.dart';
import 'package:eventhub/features/reservations/data/dtos/booking_event.dart';
import 'package:eventhub/features/reservations/data/dtos/reservation_dto.dart';
import 'package:eventhub/features/reservations/domain/attendee_name.dart';
import 'package:eventhub/features/reservations/domain/entities/reservation.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Decides a booking on what the transaction read (see `ReservationPolicy`).
typedef BookingCheck =
    Result<void> Function(Event event, Reservation? existing);

/// Decides a cancellation on the reservation the transaction read.
typedef CancellationCheck = Result<void> Function(Reservation reservation);

/// `reservations/{eventId}_{userId}` and what a seat moves around it.
///
/// Without Cloud Functions, the client writes every document itself and
/// `firebase/firestore.rules` proves each write against the others in the
/// same transaction (`getAfter`): the seat counter moves by exactly one, in
/// exactly the ticket type the reservation names, and only if the
/// reservation changes status in the same commit. The transactions below are
/// the ones `firebase/tests/reservations.rules.test.js` accepts.
///
/// Consequences with no server:
///  * the fact (seat + reservation) is atomic; its echoes — the attendee
///    entry, the team's notices, the waiting list's heads-up — are written
///    right after, best effort. Each is independently authorised by the
///    rules from the committed fact, and none may fail a booking that
///    succeeded;
///  * policy refusals are decided *inside* the transaction, on fresh reads,
///    and returned as a value rather than thrown: a refused transaction then
///    commits nothing, and the exact sentence reaches the screen instead of
///    a bare `permission-denied`.
class ReservationRemoteDataSource {
  const ReservationRemoteDataSource(this._db, this._auth);

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  /// The rules refuse a reservation list above 500 documents.
  static const maxPageSize = 500;

  /// In-app notices expire (TTL on `expiresAt`) instead of piling up.
  static const noticeLifetime = Duration(days: 30);

  /// The rules let anyone list at most 20 waiting-list entries: enough to
  /// find the first person not told yet.
  static const waitlistScan = 20;

  CollectionReference<Map<String, dynamic>> get _reservations =>
      _db.collection(Collections.reservations);

  DocumentReference<Map<String, dynamic>> _event(String eventId) =>
      _db.collection(Collections.events).doc(eventId);

  CollectionReference<Map<String, dynamic>> _notifications(String userId) => _db
      .collection(Collections.users)
      .doc(userId)
      .collection(Collections.notifications);

  // ---------------------------------------------------------------- reads

  /// A participant's tickets, most recent first (all statuses).
  Stream<List<Reservation>> watchByUser(String userId) => _reservations
      .where('userId', isEqualTo: userId)
      .orderBy('reservedAt', descending: true)
      .limit(maxPageSize)
      .snapshots()
      .map(_toList)
      .resilient('reservations:user');

  /// Confirmed seats of an event, for its team. The rules prove membership
  /// from `eventId`, so the owner and co-organizers run the same query.
  Stream<List<Reservation>> watchActiveByEvent(String eventId) => _reservations
      .where('eventId', isEqualTo: eventId)
      .where('status', isEqualTo: ReservationStatus.confirmed.name)
      .orderBy('reservedAt', descending: true)
      .limit(maxPageSize)
      .snapshots()
      .map(_toList)
      .resilient('reservations:event');

  /// Every status on the organizer's own events: cancellations are part of
  /// what an organizer monitors.
  Stream<List<Reservation>> watchByOrganizer(String organizerId) =>
      _reservations
          .where('organizerId', isEqualTo: organizerId)
          .orderBy('reservedAt', descending: true)
          .limit(maxPageSize)
          .snapshots()
          .map(_toList)
          .resilient('reservations:organizer');

  /// "Have I booked this?" is one document read, not a query: the id is
  /// known, and the rules let anyone probe their own missing seat.
  Stream<Reservation?> watchForEvent({
    required String eventId,
    required String userId,
  }) => watchById(DocIds.reservation(eventId, userId));

  Stream<Reservation?> watchById(String reservationId) => _reservations
      .doc(reservationId)
      .snapshots()
      .map(_toDomainOrNull)
      .resilient('reservation:$reservationId');

  // -------------------------------------------------------------- booking

  /// Books a free seat for [participant]: event counter(s) −1 and the
  /// reservation set to `confirmed`, in one transaction.
  ///
  /// Throws a `FailureException` carrying [check]'s refusal.
  Future<Reservation> reserve({
    required String eventId,
    required AppUser participant,
    required String? tierId,
    required BookingCheck check,
  }) async {
    final uid = participant.id;
    final reservationRef = _reservations.doc(DocIds.reservation(eventId, uid));
    // The rules compare `userEmail` with the ID token, which follows an
    // address change; the profile copy is only a fallback.
    final email = _auth.currentUser?.email ?? participant.email;

    final outcome = await _db.runTransaction<_Outcome<Map<String, dynamic>>>((
      tx,
    ) async {
      final eventSnap = await tx.get(_event(eventId));
      final eventData = eventSnap.data();
      if (eventData == null) return const _Outcome.refused(_eventGone);
      final booking = BookingEvent(eventId, eventData);
      final existing = _toDomainOrNull(await tx.get(reservationRef));

      if (check(booking.event, existing) case Err(:final failure)) {
        return _Outcome.refused(failure);
      }

      // A tier only exists on an event with ticket types; the rules refuse
      // a `tierId` on an event without.
      final tier = booking.event.hasTiers && tierId != null
          ? booking.event.tier(tierId)
          : null;
      // Client time, bounded by the rules to the server clock: it is part
      // of the booking notice id, so it must be known before the commit.
      final reservedAt = Timestamp.now();
      final data = <String, dynamic>{
        'eventId': eventId,
        'userId': uid,
        ...booking.copiedFields,
        'userName': participant.name,
        'userEmail': email,
        'status': ReservationStatus.confirmed.name,
        'reservedAt': reservedAt,
        'cancelledAt': null,
        'cancelledBy': null,
        'pricePaid': 0,
        if (tier != null) ...{'tierId': tier.id, 'tierName': tier.name},
      };
      tx
        ..update(_event(eventId), {
          'availablePlaces': booking.availablePlaces - 1,
          if (tier != null) 'tiers.${tier.id}.available': tier.available - 1,
        })
        // `set`, not `create`: re-booking after a cancellation rewrites the
        // same ticket, which the rules accept as cancelled → confirmed.
        ..set(reservationRef, data);
      return _Outcome.done(data, booking);
    });

    final data = outcome.value;
    if (data == null) throw FailureException(outcome.failure!);
    final reservation = ReservationDto.fromJson(
      data,
    ).toDomain(reservationRef.id);

    unawaited(
      _afterBooking(
        booking: outcome.event!,
        participant: participant,
        reservation: reservation,
        reservedAt: data['reservedAt'] as Timestamp,
      ),
    );
    return reservation;
  }

  /// The echoes of a committed booking. Each write is authorised by the
  /// rules from the confirmed reservation, and none can undo it.
  Future<void> _afterBooking({
    required BookingEvent booking,
    required AppUser participant,
    required Reservation reservation,
    required Timestamp reservedAt,
  }) async {
    final uid = participant.id;
    final eventRef = _event(booking.id);
    await Future.wait([
      _bestEffort(
        'attendee entry',
        () => eventRef
            .collection(Collections.attendees)
            .doc(DocIds.attendeeKey(uid))
            .set({
              'name': AttendeeName.of(participant.name),
              'createdAt': FieldValue.serverTimestamp(),
            }),
      ),
      // Someone who was waiting and got a seat leaves the queue.
      _bestEffort(
        'waitlist exit',
        () => eventRef.collection(Collections.waitlist).doc(uid).delete(),
      ),
      for (final recipient in booking.teamIds)
        _bestEffort(
          'booking notice',
          () => _notifications(recipient)
              .doc(
                'booking_${booking.id}_${uid}_'
                '${reservedAt.millisecondsSinceEpoch}',
              )
              .set(
                _notice(
                  type: 'booking',
                  title: 'Nouvelle réservation',
                  body:
                      '${participant.name} a réservé une place pour '
                      '« ${reservation.eventTitle} ».',
                  eventId: booking.id,
                  reservationId: reservation.id,
                  actorId: uid,
                ),
              ),
        ),
    ]);
  }

  // --------------------------------------------------------- cancellation

  /// Gives a free seat back: event counter(s) +1 and the reservation set to
  /// `cancelled`, in one transaction. The counter is left alone when the
  /// event no longer exists (the rules allow it: nothing to give back).
  ///
  /// Throws a `FailureException` carrying [check]'s refusal.
  Future<Reservation> cancel({
    required String reservationId,
    required String userId,
    required CancellationCheck check,
  }) async {
    final reservationRef = _reservations.doc(reservationId);

    final outcome = await _db.runTransaction<_Outcome<Reservation>>((tx) async {
      final reservation = _toDomainOrNull(await tx.get(reservationRef));
      if (reservation == null) return const _Outcome.refused(_ticketGone);
      if (check(reservation) case Err(:final failure)) {
        return _Outcome.refused(failure);
      }
      // Every read before the first write: a Firestore transaction rule.
      final eventData = (await tx.get(_event(reservation.eventId))).data();
      final booking = eventData == null
          ? null
          : BookingEvent(reservation.eventId, eventData);

      final cancelledAt = Timestamp.now();
      if (booking != null) {
        final tierId = reservation.tierId;
        final tier = booking.event.hasTiers && tierId != null
            ? booking.event.tier(tierId)
            : null;
        tx.update(_event(reservation.eventId), {
          'availablePlaces': booking.availablePlaces + 1,
          if (tier != null) 'tiers.${tier.id}.available': tier.available + 1,
        });
      }
      tx.update(reservationRef, {
        'status': ReservationStatus.cancelled.name,
        'cancelledAt': cancelledAt,
        'cancelledBy': userId,
      });
      return _Outcome.done(
        reservation.copyWith(
          status: ReservationStatus.cancelled,
          cancelledAt: cancelledAt.toDate(),
          cancelledBy: userId,
        ),
        booking,
        cancelledAt,
      );
    });

    final cancelled = outcome.value;
    if (cancelled == null) throw FailureException(outcome.failure!);
    unawaited(
      _afterCancellation(
        reservation: cancelled,
        booking: outcome.event,
        cancelledAt: outcome.at!,
      ),
    );
    return cancelled;
  }

  Future<void> _afterCancellation({
    required Reservation reservation,
    required BookingEvent? booking,
    required Timestamp cancelledAt,
  }) async {
    final uid = reservation.userId;
    final eventRef = _event(reservation.eventId);
    await Future.wait([
      _bestEffort(
        'attendee exit',
        () => eventRef
            .collection(Collections.attendees)
            .doc(DocIds.attendeeKey(uid))
            .delete(),
      ),
      if (booking != null) ...[
        for (final recipient in booking.teamIds)
          _bestEffort(
            'cancellation notice',
            () => _notifications(recipient)
                .doc(
                  'cancellation_${booking.id}_${uid}_'
                  '${cancelledAt.millisecondsSinceEpoch}',
                )
                .set(
                  _notice(
                    type: 'cancellation',
                    title: 'Réservation annulée',
                    body:
                        '${reservation.userName} a annulé sa place pour '
                        '« ${reservation.eventTitle} ».',
                    eventId: booking.id,
                    reservationId: reservation.id,
                    actorId: uid,
                  ),
                ),
          ),
        if (booking.event.startsAt.isAfter(DateTime.now()))
          _bestEffort(
            'waitlist heads-up',
            () => _notifyWaitlistHead(booking, reservation),
          ),
      ],
    ]);
  }

  /// Tells the longest-waiting person not told yet that a seat opened. No
  /// hold: the first to book gets it (the Eventbrite model).
  ///
  /// `orderBy('createdAt')` alone uses the automatic single-field index;
  /// adding `where('notifiedAt', isNull: true)` would need a composite one.
  /// Twenty entries are scanned instead, which the rules allow.
  Future<void> _notifyWaitlistHead(
    BookingEvent booking,
    Reservation cancelled,
  ) async {
    final queue = await _event(booking.id)
        .collection(Collections.waitlist)
        .orderBy('createdAt')
        .limit(waitlistScan)
        .get();
    final head = queue.docs
        .where((d) => d.data()['notifiedAt'] == null)
        .firstOrNull;
    if (head == null) return;

    // Both writes or neither: the rules check the entry exists while the
    // notice is written, and a notified entry is never told twice.
    final batch = _db.batch()
      ..update(head.reference, {'notifiedAt': FieldValue.serverTimestamp()})
      ..set(
        _notifications(
          head.id,
        ).doc('waitlist_${booking.id}_${head.id}_${cancelled.userId}'),
        _notice(
          type: 'waitlist',
          title: 'Une place s’est libérée',
          body:
              'Une place vient de se libérer pour « ${cancelled.eventTitle} ». '
              'Réservez-la avant qu’elle ne reparte.',
          eventId: booking.id,
          actorId: cancelled.userId,
        ),
      );
    await batch.commit();
  }

  // -------------------------------------------------------------- helpers

  /// The exact field list of `validNotice()` in the rules.
  static Map<String, Object?> _notice({
    required String type,
    required String title,
    required String body,
    required String eventId,
    required String actorId,
    String? reservationId,
  }) => {
    'type': type,
    'title': _clamp(title, 120),
    'body': _clamp(body, 500),
    'eventId': eventId,
    'reservationId': reservationId,
    'actorId': actorId,
    'createdAt': FieldValue.serverTimestamp(),
    'readAt': null,
    'expiresAt': Timestamp.fromDate(DateTime.now().add(noticeLifetime)),
  };

  static String _clamp(String value, int max) =>
      value.length <= max ? value : '${value.substring(0, max - 1)}…';

  /// A side effect that must never fail the action it follows: logged, so a
  /// rules regression still shows up in the logs and Crashlytics.
  static Future<void> _bestEffort(
    String label,
    Future<void> Function() write,
  ) async {
    try {
      await write();
    } on Object catch (error) {
      AppLogger.warning('Best-effort write "$label" skipped', error: error);
    }
  }

  static const _eventGone = NotFoundFailure(
    resource: 'event',
    message: 'Cet événement n’existe plus.',
  );

  static const _ticketGone = NotFoundFailure(
    resource: 'reservation',
    message: 'Réservation introuvable.',
  );

  static Reservation? _toDomainOrNull(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    return data == null
        ? null
        : ReservationDto.fromJson(data).toDomain(snapshot.id);
  }

  static List<Reservation> _toList(QuerySnapshot<Map<String, dynamic>> query) =>
      query.docs
          .map((d) => ReservationDto.fromJson(d.data()).toDomain(d.id))
          .toList(growable: false);
}

/// What a transaction decided: a value to return, or a policy refusal that
/// wrote nothing. [event] and [at] carry what the follow-up writes need.
class _Outcome<T> {
  const _Outcome.done(T this.value, this.event, [this.at]) : failure = null;

  const _Outcome.refused(Failure this.failure)
    : value = null,
      event = null,
      at = null;

  final T? value;
  final Failure? failure;
  final BookingEvent? event;
  final Timestamp? at;
}
