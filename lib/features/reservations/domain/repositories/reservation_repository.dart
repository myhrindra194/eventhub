import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/auth/domain/entities/app_user.dart';
import 'package:eventhub/features/reservations/domain/entities/reservation.dart';

abstract interface class ReservationRepository {
  /// Reservations of a participant, most recent first (all statuses).
  Stream<List<Reservation>> watchByUser(String userId);

  /// Active reservations of an event, for its organizer.
  Stream<List<Reservation>> watchByEvent({
    required String eventId,
    required String organizerId,
  });

  /// The participant's reservation for an event, `null` if none.
  Stream<Reservation?> watchForEvent({
    required String eventId,
    required String userId,
  });

  Stream<Reservation?> watchById(String reservationId);

  /// Atomically creates the reservation and decrements the event's
  /// `availablePlaces`, after checking `ReservationPolicy`.
  AsyncResult<Reservation> reserve({
    required String eventId,
    required AppUser participant,
  });

  /// Atomically cancels and releases the seat.
  AsyncResult<void> cancel({
    required String reservationId,
    required AppUser participant,
  });
}
