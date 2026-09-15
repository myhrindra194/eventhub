import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/auth/domain/entities/app_user.dart';
import 'package:eventhub/features/reservations/domain/entities/checkout.dart';
import 'package:eventhub/features/reservations/domain/entities/reservation.dart';

abstract interface class ReservationRepository {
  /// Reservations of a participant, most recent first (all statuses).
  Stream<List<Reservation>> watchByUser(String userId);

  /// Confirmed reservations of an event, for its team (owner and
  /// co-organizers see the same list).
  Stream<List<Reservation>> watchByEvent(String eventId);

  /// Every reservation (all statuses) on the organizer's events, most recent
  /// first. Feeds the organizer's statistics and activity feed.
  Stream<List<Reservation>> watchByOrganizer(String organizerId);

  /// The person's reservation for an event, `null` if none.
  Stream<Reservation?> watchForEvent({
    required String eventId,
    required String userId,
  });

  Stream<Reservation?> watchById(String reservationId);

  /// Books a free seat. `ReservationPolicy` is evaluated inside the
  /// transaction, on the event and seat it reads, and the seat is taken
  /// from the event (and the ticket type) atomically.
  AsyncResult<Reservation> reserve({
    required String eventId,
    required AppUser participant,
    String? tierId,
  });

  /// Cancels [userId]'s free seat and releases it atomically; returns the
  /// cancelled reservation.
  AsyncResult<Reservation> cancel({
    required String reservationId,
    required String userId,
  });

  /// Paid seats (F-11) need a payment server: on the Spark plan these three
  /// answer `ReservationPolicy.paymentUnavailable`.
  AsyncResult<CheckoutStart> startCheckout({
    required String eventId,
    required String tierId,
  });

  AsyncResult<void> cancelPendingCheckout({required String eventId});

  AsyncResult<void> refund({required String eventId});
}
