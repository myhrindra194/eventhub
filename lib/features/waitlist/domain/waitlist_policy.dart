import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/auth/domain/entities/app_user.dart';
import 'package:eventhub/features/events/domain/entities/event.dart';
import 'package:eventhub/features/reservations/domain/entities/reservation.dart';

/// `events/{eventId}/waitlist/{userId}` — une entrée par personne, FIFO sur
/// `createdAt` (heure du serveur).
///
/// En l’absence de serveur, celui qui rend une place prévient la tête de
/// file (les règles vérifient qu’une place est réellement libre) et horodate
/// [notifiedAt]. La place n’est retenue pour personne : la première qui
/// réserve l’emporte. Une réservation supprime l’entrée.
class WaitlistEntry {
  const WaitlistEntry({
    required this.userId,
    required this.createdAt,
    this.notifiedAt,
  });

  final String userId;

  /// `null` dans l’instantané local en attente d’une entrée fraîche.
  final DateTime? createdAt;

  /// Quand cette personne a été prévenue qu’une place s’était libérée.
  final DateTime? notifiedAt;
}

/// Reflétée dans la condition de création `waitlist` des règles, qui
/// tranche.
abstract final class WaitlistPolicy {
  /// Un seul compte porte les deux espaces : un organisateur attend pour les
  /// événements des autres comme n’importe qui. Seule l’équipe de
  /// l’événement est exclue — elle ne peut pas y réserver, une place dans sa
  /// file n’aurait donc aucun sens.
  static Result<void> canJoin({
    required Event event,
    required AppUser user,
    required Reservation? reservation,
    required DateTime now,
  }) {
    if (event.isManagedBy(user.id)) {
      return const Err(
        PermissionFailure(
          message:
              'Vous faites partie de l’équipe de cet événement : sa liste '
              'd’attente ne vous concerne pas.',
        ),
      );
    }
    if (reservation != null && reservation.isActive) {
      return const Err(
        BusinessRuleFailure(
          rule: BusinessRule.alreadyReserved,
          message: 'Vous avez déjà une place pour cet événement.',
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
    if (!event.isFull) {
      return const Err(
        BusinessRuleFailure(
          rule: BusinessRule.waitlistNotAvailable,
          message: 'Des places sont disponibles : réservez directement.',
        ),
      );
    }
    return const Ok(null);
  }
}
