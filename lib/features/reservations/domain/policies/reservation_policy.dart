import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/events/domain/entities/event.dart';
import 'package:eventhub/features/reservations/domain/entities/reservation.dart';

/// Business rules from the spec (§4.4 / §7). Pure and unit-tested; evaluated
/// inside the Firestore transaction so concurrent bookings cannot overbook.
abstract final class ReservationPolicy {
  static Result<void> canReserve({
    required Event event,
    required Reservation? existing,
    required DateTime now,
  }) {
    if (existing != null && existing.isActive) {
      return const Err(
        BusinessRuleFailure(
          rule: BusinessRule.alreadyReserved,
          message: 'Vous avez déjà réservé cet événement.',
        ),
      );
    }
    if (event.hasStarted(now)) {
      return const Err(
        BusinessRuleFailure(
          rule: BusinessRule.eventAlreadyStarted,
          message: 'Cet événement a déjà commencé.',
        ),
      );
    }
    if (event.isFull) {
      return const Err(
        BusinessRuleFailure(
          rule: BusinessRule.eventFull,
          message: 'Cet événement est complet.',
        ),
      );
    }
    return const Ok(null);
  }

  static Result<void> canCancel({
    required Reservation reservation,
    required String userId,
  }) {
    if (reservation.userId != userId) {
      return const Err(
        BusinessRuleFailure(
          rule: BusinessRule.notReservationOwner,
          message: 'Cette réservation ne vous appartient pas.',
        ),
      );
    }
    if (!reservation.isActive) {
      return const Err(
        BusinessRuleFailure(
          rule: BusinessRule.reservationNotActive,
          message: 'Cette réservation est déjà annulée.',
        ),
      );
    }
    return const Ok(null);
  }
}
