import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/auth/domain/entities/app_user.dart';
import 'package:eventhub/features/events/domain/entities/event.dart';
import 'package:eventhub/features/reservations/domain/entities/reservation.dart';

/// `events/{eventId}/waitlist/{userId}` — one entry per person, FIFO by
/// `createdAt`.
///
/// When a seat is released, the `notifyWaitlistOnSeatRelease` Cloud Function
/// notifies as many people as seats freed, oldest first. There is no hold on
/// the seat: the first to book gets it. A reservation removes the entry.
class WaitlistEntry {
  const WaitlistEntry({
    required this.userId,
    required this.userName,
    required this.createdAt,
    this.notifiedAt,
  });

  final String userId;
  final String userName;
  final DateTime createdAt;

  /// Set by the server when this person was told a seat opened.
  final DateTime? notifiedAt;
}

/// Mirrored in `firestore.rules` (`waitlist` create).
abstract final class WaitlistPolicy {
  static Result<void> canJoin({
    required Event event,
    required AppUser user,
    required Reservation? reservation,
    required DateTime now,
  }) {
    if (!user.isParticipant) {
      return const Err(
        PermissionFailure(
          message: 'Seul un participant peut rejoindre une liste d’attente.',
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
