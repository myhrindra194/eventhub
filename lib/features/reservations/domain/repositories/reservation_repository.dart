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

  /// The participant's reservation for an event, `null` if none.
  Stream<Reservation?> watchForEvent({
    required String eventId,
    required String userId,
  });

  Stream<Reservation?> watchById(String reservationId);

  /// Books a free seat. The database re-checks `ReservationPolicy` and
  /// takes the seat from the event (and the ticket type) atomically.
  AsyncResult<Reservation> reserve({
    required String eventId,
    required AppUser participant,
    String? tierId,
  });

  /// Cancels a free seat and releases it atomically; returns the cancelled
  /// reservation.
  AsyncResult<Reservation> cancel({required String reservationId});

  /// Holds a paid seat and opens a Stripe Checkout session for it.
  AsyncResult<CheckoutStart> startCheckout({
    required String eventId,
    required String tierId,
  });

  /// Gives up a held seat before paying.
  AsyncResult<void> cancelPendingCheckout({required String eventId});

  /// Refunds a paid ticket and releases the seat.
  AsyncResult<void> refund({required String eventId});
}
