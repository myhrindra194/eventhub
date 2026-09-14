import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/auth/domain/entities/app_user.dart';
import 'package:eventhub/features/events/domain/entities/event.dart';
import 'package:eventhub/features/events/domain/policies/event_policy.dart';

enum InvitationStatus {
  pending,
  accepted,
  declined;

  static InvitationStatus fromWire(Object? value) => switch (value) {
    'accepted' => accepted,
    'declined' => declined,
    _ => pending,
  };
}

/// An invitation to co-organize (F-16). Same shape under the event
/// (`events/{id}/invitations/{uid}`) and under the invitee
/// (`users/{uid}/staffInvitations/{eventId}`); written by Cloud Functions.
class StaffInvitation {
  const StaffInvitation({
    required this.eventId,
    required this.userId,
    required this.email,
    required this.name,
    required this.invitedByName,
    required this.eventTitle,
    required this.status,
    this.eventStartsAt,
    this.createdAt,
  });

  final String eventId;
  final String userId;
  final String email;
  final String name;
  final String invitedByName;
  final String eventTitle;
  final DateTime? eventStartsAt;
  final InvitationStatus status;
  final DateTime? createdAt;

  bool get isPending => status == InvitationStatus.pending;
}

/// Client-side checks before calling the team functions, so the owner gets
/// a sentence instead of a round trip. The server re-checks everything.
abstract final class TeamPolicy {
  static Result<void> canInvite({
    required Event event,
    required AppUser user,
    required String email,
    required int pendingCount,
    required DateTime now,
  }) {
    if (EventPolicy.canManageTeam(event: event, user: user) case Err(
      :final failure,
    )) {
      return Err(failure);
    }
    final address = email.trim().toLowerCase();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(address)) {
      return const Err(ValidationFailure(message: 'Adresse email invalide.'));
    }
    if (address == user.email.trim().toLowerCase()) {
      return const Err(
        ValidationFailure(
          message: 'C’est votre adresse : vous êtes déjà l’organisateur.',
        ),
      );
    }
    if (event.hasStarted(now)) {
      return const Err(
        BusinessRuleFailure(
          rule: BusinessRule.eventAlreadyStarted,
          message: 'Cet événement est passé.',
        ),
      );
    }
    if (event.staffIds.length + pendingCount >= EventPolicy.maxStaff) {
      return const Err(
        BusinessRuleFailure(
          rule: BusinessRule.actionRefused,
          message:
              'Équipe complète : ${EventPolicy.maxStaff} co-organisateurs au '
              'plus.',
        ),
      );
    }
    return const Ok(null);
  }
}
