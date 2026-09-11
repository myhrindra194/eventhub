import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/auth/domain/entities/app_user.dart';
import 'package:eventhub/features/events/domain/entities/event.dart';

/// Ownership and capacity rules for organizers. Pure, synchronous, unit-tested.
/// Mirrored server-side in `firestore.rules`.
abstract final class EventPolicy {
  static Result<void> canManage({required Event event, required AppUser user}) {
    if (!user.isOrganizer || !event.isOwnedBy(user.id)) {
      return const Err(
        BusinessRuleFailure(
          rule: BusinessRule.notEventOwner,
          message: 'Vous ne pouvez gérer que vos propres événements.',
        ),
      );
    }
    return const Ok(null);
  }

  /// A capacity change must keep room for existing reservations.
  static Result<int> availablePlacesAfterCapacityChange({
    required Event event,
    required int newCapacity,
  }) {
    if (newCapacity < event.reservedCount) {
      return Err(
        BusinessRuleFailure(
          rule: BusinessRule.capacityBelowReservations,
          message:
              'La capacité ne peut pas être inférieure aux ${event.reservedCount} '
              'réservations existantes.',
        ),
      );
    }
    return Ok(newCapacity - event.reservedCount);
  }
}
