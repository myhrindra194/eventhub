import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/auth/domain/entities/app_user.dart';
import 'package:eventhub/features/events/domain/entities/event.dart';
import 'package:eventhub/features/reservations/domain/entities/reservation.dart';

/// `events/{eventId}/waitlist/{userId}` — one entry per person, FIFO by
/// `createdAt` (server time).
///
/// With no server, whoever gives a seat back tells the head of the queue
/// (the rules check a seat is really free) and stamps [notifiedAt]. There
/// is no hold on the seat: the first to book gets it. A booking removes the
/// entry.
class WaitlistEntry {
  const WaitlistEntry({
    required this.userId,
    required this.createdAt,
    this.notifiedAt,
  });

  final String userId;

  /// `null` in the pending local snapshot of a fresh entry.
  final DateTime? createdAt;

  /// When this person was told a seat opened.
  final DateTime? notifiedAt;
}

/// Mirrored in the rules' `waitlist` create condition, which decides.
abstract final class WaitlistPolicy {
  /// One account holds both spaces: an organizer waits for other people's
  /// events like anyone else. Only the event's own team is excluded — it
  /// cannot book the event, so a place in its queue would be meaningless.
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
