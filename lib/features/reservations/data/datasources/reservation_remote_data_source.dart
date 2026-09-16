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

/// Décide d’une réservation d’après ce que la transaction a lu (voir
/// `ReservationPolicy`).
typedef BookingCheck =
    Result<void> Function(Event event, Reservation? existing);

/// Décide d’une annulation d’après la réservation lue par la transaction.
typedef CancellationCheck = Result<void> Function(Reservation reservation);

/// `reservations/{eventId}_{userId}` et tout ce qu’une place déplace autour
/// de lui.
///
/// Sans Cloud Functions, le client écrit lui-même chaque document et
/// `firebase/firestore.rules` prouve chaque écriture à partir des autres de
/// la même transaction (`getAfter`) : le compteur de places bouge d’une
/// unité exactement, dans exactement le type de billet que la réservation
/// nomme, et seulement si la réservation change de statut dans le même
/// commit. Les transactions ci-dessous sont celles qu’accepte
/// `firebase/tests/reservations.rules.test.js`.
///
/// Conséquences en l’absence de serveur :
///  * le fait (place + réservation) est atomique ; ses échos — l’entrée
///    dans les participants, les notifications de l’équipe, l’alerte à la
///    liste d’attente — sont écrits juste après, au mieux. Chacun est
///    autorisé indépendamment par les règles à partir du fait déjà
///    committé, et aucun ne doit faire échouer une réservation qui a
///    réussi ;
///  * les refus de la policy sont décidés *à l’intérieur* de la
///    transaction, sur des lectures fraîches, et renvoyés comme valeur
///    plutôt que levés : une transaction refusée ne committe alors rien, et
///    la phrase exacte atteint l’écran au lieu d’un simple
///    `permission-denied`.
class ReservationRemoteDataSource {
  const ReservationRemoteDataSource(this._db, this._auth);

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  /// Les règles refusent une liste de réservations au-delà de 500 documents.
  static const maxPageSize = 500;

  /// Les notifications in-app expirent (TTL sur `expiresAt`) au lieu de
  /// s’accumuler.
  static const noticeLifetime = Duration(days: 30);

  /// Les règles n’autorisent à lister que 20 entrées de liste d’attente au
  /// plus : assez pour trouver la première personne pas encore prévenue.
  static const waitlistScan = 20;

  CollectionReference<Map<String, dynamic>> get _reservations =>
      _db.collection(Collections.reservations);

  DocumentReference<Map<String, dynamic>> _event(String eventId) =>
      _db.collection(Collections.events).doc(eventId);

  CollectionReference<Map<String, dynamic>> _notifications(String userId) => _db
      .collection(Collections.users)
      .doc(userId)
      .collection(Collections.notifications);

  // ------------------------------------------------------------- lectures

  /// Les billets d’un participant, les plus récents d’abord (tous statuts).
  Stream<List<Reservation>> watchByUser(String userId) => _reservations
      .where('userId', isEqualTo: userId)
      .orderBy('reservedAt', descending: true)
      .limit(maxPageSize)
      .snapshots()
      .map(_toList)
      .resilient('reservations:user');

  /// Les places confirmées d’un événement, pour son équipe. Les règles
  /// prouvent l’appartenance à partir de `eventId`, si bien que le
  /// propriétaire et les co-organisateurs lancent la même requête.
  Stream<List<Reservation>> watchActiveByEvent(String eventId) => _reservations
      .where('eventId', isEqualTo: eventId)
      .where('status', isEqualTo: ReservationStatus.confirmed.name)
      .orderBy('reservedAt', descending: true)
      .limit(maxPageSize)
      .snapshots()
      .map(_toList)
      .resilient('reservations:event');

  /// Tous les statuts sur les événements propres à l’organisateur : les
  /// annulations font partie de ce qu’un organisateur surveille.
  Stream<List<Reservation>> watchByOrganizer(String organizerId) =>
      _reservations
          .where('organizerId', isEqualTo: organizerId)
          .orderBy('reservedAt', descending: true)
          .limit(maxPageSize)
          .snapshots()
          .map(_toList)
          .resilient('reservations:organizer');

  /// « Ai-je réservé cet événement ? » est une lecture de document, pas une
  /// requête : l’id est connu, et les règles laissent chacun sonder sa
  /// propre place absente.
  Stream<Reservation?> watchForEvent({
    required String eventId,
    required String userId,
  }) => watchById(DocIds.reservation(eventId, userId));

  Stream<Reservation?> watchById(String reservationId) => _reservations
      .doc(reservationId)
      .snapshots()
      .map(_toDomainOrNull)
      .resilient('reservation:$reservationId');

  // ---------------------------------------------------------- réservation

  /// Réserve une place gratuite pour [participant] : compteur(s) de
  /// l’événement −1 et réservation passée à `confirmed`, en une seule
  /// transaction.
  ///
  /// Lève une `FailureException` portant le refus de [check].
  Future<Reservation> reserve({
    required String eventId,
    required AppUser participant,
    required String? tierId,
    required BookingCheck check,
  }) async {
    final uid = participant.id;
    final reservationRef = _reservations.doc(DocIds.reservation(eventId, uid));
    // Les règles comparent `userEmail` au jeton d’identité, qui suit un
    // changement d’adresse ; la copie du profil n’est qu’un repli.
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

      // Un tier n’existe que sur un événement doté de types de billets ;
      // les règles refusent un `tierId` sur un événement qui n’en a pas.
      final tier = booking.event.hasTiers && tierId != null
          ? booking.event.tier(tierId)
          : null;
      // Heure du client, bornée par les règles à l’horloge du serveur :
      // elle entre dans l’id de la notification de réservation, et doit
      // donc être connue avant le commit.
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
        // `set`, pas `create` : réserver à nouveau après une annulation
        // réécrit le même billet, ce que les règles acceptent comme
        // cancelled → confirmed.
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

  /// Les échos d’une réservation déjà committée. Chaque écriture est
  /// autorisée par les règles à partir de la réservation confirmée, et
  /// aucune ne peut la défaire.
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
      // Une personne qui attendait et obtient une place quitte la file.
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

  // ----------------------------------------------------------- annulation

  /// Rend une place gratuite : compteur(s) de l’événement +1 et réservation
  /// passée à `cancelled`, en une seule transaction. Le compteur est laissé
  /// tel quel quand l’événement n’existe plus (les règles l’autorisent : il
  /// n’y a rien à rendre).
  ///
  /// Lève une `FailureException` portant le refus de [check].
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
      // Toutes les lectures avant la première écriture : c’est la règle des
      // transactions Firestore.
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

  /// Prévient qu’une place s’est libérée la personne qui attend depuis le
  /// plus longtemps et n’a pas encore été prévenue. Aucune place n’est
  /// retenue à son nom : la première qui réserve l’emporte (le modèle
  /// Eventbrite).
  ///
  /// `orderBy('createdAt')` seul utilise l’index automatique à champ
  /// unique ; y ajouter `where('notifiedAt', isNull: true)` en exigerait un
  /// composite. On parcourt donc vingt entrées, ce que les règles
  /// autorisent.
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

    // Les deux écritures ou aucune : les règles vérifient que l’entrée
    // existe au moment où la notification est écrite, et une entrée déjà
    // prévenue ne l’est jamais deux fois.
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

  // ---------------------------------------------------------- utilitaires

  /// La liste exacte des champs de `validNotice()` dans les règles.
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

  /// Un effet de bord qui ne doit jamais faire échouer l’action qu’il
  /// suit : journalisé, pour qu’une régression des règles reste visible
  /// dans les logs et dans Crashlytics.
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

/// Ce qu’une transaction a décidé : une valeur à renvoyer, ou un refus de
/// la policy qui n’a rien écrit. [event] et [at] transportent ce dont les
/// écritures de suivi ont besoin.
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
