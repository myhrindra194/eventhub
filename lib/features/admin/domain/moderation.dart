import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/moderation/domain/report.dart';

/// Where an entry of `moderation_queue` stands (`moderation_status`).
enum ModerationStatus {
  open,
  resolved,
  dismissed;

  static ModerationStatus fromWire(Object? value) => switch (value) {
    'resolved' => resolved,
    'dismissed' => dismissed,
    _ => open,
  };
}

/// A decision an administrator can take. Wire values are the
/// `moderation_action` enum; the per-target lists mirror the check at the
/// top of `public.moderate_content`.
enum ModerationAction {
  hide(
    'hide',
    'Masquer l’avis',
    'L’avis disparaît de la fiche et de la note de l’organisateur. Son '
        'auteur est prévenu.',
    destructive: true,
  ),
  restore(
    'restore',
    'Rétablir l’avis',
    'L’avis réapparaît et compte de nouveau dans la note. Le seuil '
        'automatique ne le masquera plus.',
  ),
  removeEvent(
    'removeEvent',
    'Retirer l’événement',
    'Toutes les réservations sont annulées, chaque inscrit et l’organisateur '
        'sont prévenus, puis l’événement est supprimé. Irréversible.',
    requiresNote: true,
    destructive: true,
  ),
  suspend(
    'suspend',
    'Suspendre le compte',
    'La personne ne peut plus se connecter ; ses sessions ouvertes expirent '
        'dans l’heure. Ses événements restent en ligne : retirez-les à part si '
        'nécessaire.',
    requiresNote: true,
    destructive: true,
  ),
  reinstate(
    'reinstate',
    'Réactiver le compte',
    'La personne peut de nouveau se connecter.',
  ),
  dismiss(
    'dismiss',
    'Classer sans suite',
    'Le contenu reste tel quel ; le dossier passe dans « Traités ».',
  );

  const ModerationAction(
    this.wire,
    this.label,
    this.consequence, {
    this.requiresNote = false,
    this.destructive = false,
  });

  final String wire;
  final String label;

  /// What happens, in one or two sentences, shown before confirming.
  final String consequence;

  /// The note is sent to the person concerned: a removal or a suspension
  /// without a reason is not acceptable.
  final bool requiresNote;
  final bool destructive;

  static ModerationAction? fromWire(Object? value) {
    for (final action in values) {
      if (action.wire == value) return action;
    }
    return null;
  }
}

/// One entry of `public.moderation_queue`, one per reported target.
class ModerationEntry {
  const ModerationEntry({
    required this.id,
    required this.target,
    required this.targetId,
    required this.reportCount,
    required this.status,
    this.lastReason,
    this.autoHidden = false,
    this.decision,
    this.decisionNote,
    this.decidedAt,
    this.updatedAt,
  });

  final String id;
  final ReportTarget target;
  final String targetId;
  final int reportCount;
  final ModerationStatus status;
  final ReportReason? lastReason;

  /// The review was hidden by the automatic threshold, not by a person.
  final bool autoHidden;
  final ModerationAction? decision;
  final String? decisionNote;
  final DateTime? decidedAt;
  final DateTime? updatedAt;

  bool get isOpen => status == ModerationStatus.open;

  /// Entry ids are `<targetType>_<targetId>` (e.g. `review_<uuid>`), the
  /// format stamped by the database and used in routes.
  static String composeId(ReportTarget target, String targetId) =>
      '${target.name}_$targetId';

  /// Inverse of [composeId]. Splits on the first underscore: the type never
  /// contains one, a target id may.
  static (ReportTarget, String)? parseId(String id) {
    final cut = id.indexOf('_');
    if (cut <= 0 || cut == id.length - 1) return null;
    final type = id.substring(0, cut);
    for (final target in ReportTarget.values) {
      if (target.name == type) return (target, id.substring(cut + 1));
    }
    return null;
  }
}

/// A report as an administrator sees it: never the reporter's identity,
/// only a short stable key to spot one account reporting many things.
class ReportRecord {
  const ReportRecord({
    required this.id,
    required this.reason,
    required this.details,
    required this.createdAt,
    required this.reporterKey,
  });

  final String id;
  final ReportReason? reason;
  final String details;
  final DateTime? createdAt;
  final String reporterKey;
}

class ModerationDecision {
  const ModerationDecision({
    required this.action,
    required this.note,
    required this.by,
    required this.at,
  });

  final ModerationAction? action;
  final String note;
  final String by;
  final DateTime? at;
}

/// The reported account, read from `public.profiles` (admins may read any).
class ReportedAccount {
  const ReportedAccount({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final DateTime? createdAt;
}

/// `public.administrators` — who holds the back-office role.
class AdminAccount {
  const AdminAccount({
    required this.id,
    required this.email,
    this.name,
    this.grantedBy,
    this.grantedAt,
  });

  final String id;
  final String email;
  final String? name;
  final String? grantedBy;
  final DateTime? grantedAt;
}

/// What a moderator may do next. Pure, so the screen and the tests agree
/// with the server list.
abstract final class ModerationPolicy {
  static const maxNote = 500;

  static List<ModerationAction> actionsFor(
    ReportTarget target, {
    bool reviewHidden = false,
    bool accountSuspended = false,
  }) => switch (target) {
    ReportTarget.review => [
      if (reviewHidden) ModerationAction.restore else ModerationAction.hide,
      ModerationAction.dismiss,
    ],
    ReportTarget.event => const [
      ModerationAction.removeEvent,
      ModerationAction.dismiss,
    ],
    ReportTarget.user => [
      if (accountSuspended)
        ModerationAction.reinstate
      else
        ModerationAction.suspend,
      ModerationAction.dismiss,
    ],
  };

  /// The last decision tells whether the account is currently suspended:
  /// `moderate_content` is the only way to suspend or reinstate.
  static bool isSuspended(ModerationEntry? entry) =>
      entry?.target == ReportTarget.user &&
      entry?.decision == ModerationAction.suspend;

  static Result<void> validateNote(ModerationAction action, String note) {
    final text = note.trim();
    if (action.requiresNote && text.isEmpty) {
      return const Err(
        ValidationFailure(
          message: 'Expliquez la décision : la personne concernée la recevra.',
        ),
      );
    }
    if (text.length > maxNote) {
      return const Err(ValidationFailure(message: '500 caractères maximum.'));
    }
    return const Ok(null);
  }

  static Result<void> validateEmail(String email) {
    final text = email.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)) {
      return const Err(ValidationFailure(message: 'Adresse email invalide.'));
    }
    return const Ok(null);
  }
}
