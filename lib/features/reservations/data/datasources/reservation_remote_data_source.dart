import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventhub/core/config/app_config.dart';
import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/errors/failure_exception.dart';
import 'package:eventhub/core/firebase/firestore_paths.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/auth/domain/entities/app_user.dart';
import 'package:eventhub/features/events/data/dtos/event_dto.dart';
import 'package:eventhub/features/reservations/data/dtos/reservation_dto.dart';
import 'package:eventhub/features/reservations/domain/entities/reservation.dart';
import 'package:eventhub/features/reservations/domain/policies/reservation_policy.dart';

/// Firestore access for `reservations/{id}`.
///
/// `reserve` and `cancel` run as transactions touching both the reservation
/// and the event document, so `availablePlaces` can never drift from the
/// number of active reservations, even under concurrent bookings.
class ReservationRemoteDataSource {
  ReservationRemoteDataSource(FirebaseFirestore firestore, this._clock)
    : _firestore = firestore,
      _reservations = firestore.collection(FirestorePaths.reservations),
      _events = firestore.collection(FirestorePaths.events);

  final FirebaseFirestore _firestore;
  final Clock _clock;
  final CollectionReference<Map<String, dynamic>> _reservations;
  final CollectionReference<Map<String, dynamic>> _events;

  /// Upper bound applied to every list query — mirrors the ceiling declared
  /// in `firestore.rules` (`request.query.limit <= 200`), which rejects an
  /// unbounded `list` request.
  static const maxPageSize = 200;

  Stream<List<Reservation>> watchByUser(String userId) {
    return _reservations
        .where(ReservationFields.userId, isEqualTo: userId)
        .orderBy(ReservationFields.reservedAt, descending: true)
        .limit(maxPageSize)
        .snapshots()
        .map(_toDomainList);
  }

  Stream<List<Reservation>> watchActiveByEvent({
    required String eventId,
    required String organizerId,
  }) {
    // Both equality filters are required by the security rules so the query
    // is provably restricted to the organizer's own data.
    return _reservations
        .where(ReservationFields.eventId, isEqualTo: eventId)
        .where(ReservationFields.organizerId, isEqualTo: organizerId)
        .where(
          ReservationFields.status,
          isEqualTo: ReservationStatus.confirmed.name,
        )
        .orderBy(ReservationFields.reservedAt, descending: true)
        .limit(maxPageSize)
        .snapshots()
        .map(_toDomainList);
  }

  Stream<Reservation?> watchById(String reservationId) =>
      _reservations.doc(reservationId).snapshots().map(_toDomainOrNull);

  Future<Reservation> reserve({
    required String eventId,
    required AppUser participant,
  }) {
    final eventRef = _events.doc(eventId);
    final reservationId = Reservation.composeId(
      eventId: eventId,
      userId: participant.id,
    );
    final reservationRef = _reservations.doc(reservationId);

    return _firestore.runTransaction<Reservation>((tx) async {
      final eventSnap = await tx.get(eventRef);
      final eventData = eventSnap.data();
      if (eventData == null) {
        throw FailureException(
          NotFoundFailure(
            resource: 'events/$eventId',
            message: 'Cet événement n\'existe plus.',
          ),
        );
      }
      final event = EventDto.fromJson(eventData).toDomain(eventSnap.id);
      final existing = _toDomainOrNull(await tx.get(reservationRef));
      final now = _clock();

      if (ReservationPolicy.canReserve(
            event: event,
            existing: existing,
            now: now,
          )
          case Err(:final failure)) {
        throw FailureException(failure);
      }

      final reservation = Reservation(
        id: reservationId,
        eventId: event.id,
        userId: participant.id,
        organizerId: event.organizerId,
        userName: participant.name,
        userEmail: participant.email,
        eventTitle: event.title,
        eventStartsAt: event.startsAt,
        eventLocation: event.location,
        status: ReservationStatus.confirmed,
        reservedAt: now,
      );

      tx
        ..set(reservationRef, ReservationDto.fromDomain(reservation).toJson())
        ..update(eventRef, {
          EventFields.availablePlaces: FieldValue.increment(-1),
          EventFields.updatedAt: FieldValue.serverTimestamp(),
        });
      return reservation;
    });
  }

  Future<void> cancel({
    required String reservationId,
    required AppUser participant,
  }) {
    final reservationRef = _reservations.doc(reservationId);

    return _firestore.runTransaction<void>((tx) async {
      final reservation = _toDomainOrNull(await tx.get(reservationRef));
      if (reservation == null) {
        throw FailureException(
          NotFoundFailure(
            resource: 'reservations/$reservationId',
            message: 'Réservation introuvable.',
          ),
        );
      }
      if (ReservationPolicy.canCancel(
            reservation: reservation,
            userId: participant.id,
          )
          case Err(:final failure)) {
        throw FailureException(failure);
      }

      final eventRef = _events.doc(reservation.eventId);
      final eventSnap = await tx.get(eventRef);

      tx.update(reservationRef, {
        ReservationFields.status: ReservationStatus.cancelled.name,
        ReservationFields.cancelledAt: Timestamp.fromDate(_clock()),
      });
      // The event may have been deleted meanwhile: releasing a seat on a
      // missing document must not fail the cancellation.
      if (eventSnap.exists) {
        tx.update(eventRef, {
          EventFields.availablePlaces: FieldValue.increment(1),
          EventFields.updatedAt: FieldValue.serverTimestamp(),
        });
      }
    });
  }

  List<Reservation> _toDomainList(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) => snapshot.docs
      .map((doc) => ReservationDto.fromJson(doc.data()).toDomain(doc.id))
      .toList(growable: false);

  Reservation? _toDomainOrNull(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    return data == null
        ? null
        : ReservationDto.fromJson(data).toDomain(snapshot.id);
  }
}
