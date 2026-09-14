import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/auth/domain/entities/app_user.dart';
import 'package:eventhub/features/reservations/domain/entities/checkout.dart';
import 'package:eventhub/features/reservations/domain/entities/reservation.dart';

abstract interface class ReservationRepository {
  /// Reservations of a participant, most recent first (all statuses).
  Stream<List<Reservation>> watchByUser(String userId);

  /// Active reservations of an event, for its organizer.
  Stream<List<Reservation>> watchByEvent({
    required String eventId,
    required String organizerId,
  });

  /// Active reservations of an event, for one of its co-organizers.
  Stream<List<Reservation>> watchByEventForTeam(String eventId);

  /// Every reservation (all statuses) on the organizer's events, most recent
  /// first. Feeds the organizer's statistics and activity feed.
  Stream<List<Reservation>> watchByOrganizer(String organizerId);

  /// The participant's reservation for an event, `null` if none.
  Stream<Reservation?> watchForEvent({
    required String eventId,
    required String userId,
  });

  Stream<Reservation?> watchById(String reservationId);

  /// Atomically creates the reservation and decrements the event's
  /// `availablePlaces` (and the ticket type's), after checking
  /// `ReservationPolicy`. Free seats only.
  AsyncResult<Reservation> reserve({
    required String eventId,
    required AppUser participant,
    String? tierId,
  });

  /// Atomically cancels and releases the seat. Free seats only.
  AsyncResult<void> cancel({
    required String reservationId,
    required AppUser participant,
  });

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
