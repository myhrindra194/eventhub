import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/auth/domain/entities/app_user.dart';
import 'package:eventhub/features/events/domain/entities/event.dart';

/// Ownership, team and capacity rules for organizers. Pure, synchronous,
/// unit-tested. Mirrored server-side in `firestore.rules` and the team
/// Cloud Functions.
///
/// | action                      | owner | co-organizer |
/// |-----------------------------|:-----:|:------------:|
/// | edit content, guest list, door | ✓  | ✓            |
/// | delete the event            | ✓     |              |
/// | invite / remove members     | ✓     | leave only   |
abstract final class EventPolicy {
  /// Maximum co-organizers per event (owner excluded).
  static const maxStaff = 10;

  static Result<void> canManage({required Event event, required AppUser user}) {
    if (!user.isOrganizer || !event.isManagedBy(user.id)) {
      return const Err(
        BusinessRuleFailure(
          rule: BusinessRule.notEventOwner,
          message:
              'Vous ne pouvez gérer que vos événements ou ceux que vous '
              'co-organisez.',
        ),
      );
    }
    return const Ok(null);
  }

  static Result<void> _owner(Event event, AppUser user, String message) {
    if (!user.isOrganizer || !event.isOwnedBy(user.id)) {
      return Err(
        BusinessRuleFailure(rule: BusinessRule.notEventOwner, message: message),
      );
    }
    return const Ok(null);
  }

  /// An event with seats taken cannot be deleted: people hold tickets for it.
  /// Mirrors `allow delete: if isOwner() && takenSeats() == 0` in the rules,
  /// so the organizer gets a sentence instead of a permission error.
  static Result<void> canDelete({required Event event, required AppUser user}) {
    if (_owner(
          event,
          user,
          'Seul l’organisateur principal peut supprimer cet événement.',
        )
        case Err(:final failure)) {
      return Err(failure);
    }
    if (event.reservedCount > 0) {
      final n = event.reservedCount;
      return Err(
        BusinessRuleFailure(
          rule: BusinessRule.eventHasReservations,
          message:
              'Impossible de supprimer : $n participant'
              '${n > 1 ? 's ont' : ' a'} réservé. Modifiez l’événement, ou '
              'attendez que les places soient libérées.',
        ),
      );
    }
    return const Ok(null);
  }

  /// Inviting and removing co-organizers is the owner's call.
  static Result<void> canManageTeam({
    required Event event,
    required AppUser user,
  }) => _owner(event, user, 'Seul l’organisateur principal compose l’équipe.');

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
