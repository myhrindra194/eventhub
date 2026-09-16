import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/auth/domain/entities/app_user.dart';
import 'package:eventhub/features/events/domain/entities/event.dart';

/// Règles de propriété, d’équipe et de capacité pour les organisateurs.
/// Pures, synchrones, couvertes par des tests unitaires. Dupliquées côté
/// serveur par `firebase/firestore.rules`, qui ne répondent jamais autre
/// chose que `permission-denied` : ici, on donne la phrase.
///
/// | action                           | proprio | co-organisateur    |
/// |----------------------------------|:-------:|:------------------:|
/// | modifier contenu, liste, accueil | ✓       | ✓                  |
/// | supprimer l’événement            | ✓       |                    |
/// | inviter / retirer des membres    | ✓       | quitter uniquement |
abstract final class EventPolicy {
  /// Nombre maximal de co-organisateurs par événement (propriétaire exclu).
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

  /// Un événement dont des places sont prises ne peut pas être supprimé :
  /// des gens en détiennent les billets. Duplique la règle de suppression
  /// (`takenSeats() == 0`), pour que l’organisateur obtienne une phrase
  /// avant même l’aller-retour serveur.
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

  /// Inviter et retirer des co-organisateurs relève du propriétaire.
  static Result<void> canManageTeam({
    required Event event,
    required AppUser user,
  }) => _owner(event, user, 'Seul l’organisateur principal compose l’équipe.');

  /// Un changement de capacité doit laisser de la place aux réservations
  /// existantes.
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
