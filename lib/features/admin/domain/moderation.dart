import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/moderation/domain/report.dart';

/// Où en est une entrée de `moderationQueue`.
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

/// Une décision qu’un administrateur peut prendre. La valeur `wire` est celle
/// qui atterrit dans `moderationQueue/{id}.decision` et dans l’historique des
/// décisions ; les listes par type de cible reflètent ce que les règles de
/// sécurité autorisent réellement.
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
    'L’avis réapparaît et compte de nouveau dans la note. Son auteur est '
        'prévenu.',
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
    'La personne peut encore lire, mais n’écrit plus rien : ni réservation, '
        'ni avis, ni événement. Ses événements restent en ligne : retirez-les '
        'à part si nécessaire.',
    requiresNote: true,
    destructive: true,
  ),
  reinstate(
    'reinstate',
    'Réactiver le compte',
    'La personne retrouve l’usage complet de son compte.',
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

  /// Ce qui se passe, en une ou deux phrases, affiché avant de confirmer.
  final String consequence;

  /// La note est transmise à la personne concernée : un retrait ou une
  /// suspension sans motif n’est pas acceptable.
  final bool requiresNote;
  final bool destructive;

  static ModerationAction? fromWire(Object? value) {
    for (final action in values) {
      if (action.wire == value) return action;
    }
    return null;
  }
}

/// Une entrée de `moderationQueue`, une par cible signalée.
class ModerationEntry {
  const ModerationEntry({
    required this.id,
    required this.target,
    required this.targetId,
    required this.reportCount,
    required this.status,
    this.lastReason,
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
  final ModerationAction? decision;
  final String? decisionNote;
  final DateTime? decidedAt;
  final DateTime? updatedAt;

  bool get isOpen => status == ModerationStatus.open;

  /// Les identifiants d’entrée sont `<targetType>_<targetId>` (par ex.
  /// `review_e1_u1`), le format que les règles reconstruisent pour prouver
  /// qu’un signalement appartient bien à son entrée, et celui qu’utilisent les
  /// routes.
  static String composeId(ReportTarget target, String targetId) =>
      '${target.name}_$targetId';

  /// Inverse de [composeId]. Découpe au premier tiret bas : le type n’en
  /// contient jamais, un identifiant de cible peut en contenir.
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

/// Un signalement tel qu’un administrateur le voit : jamais l’identité de son
/// auteur, seulement une courte clé stable permettant de repérer un compte qui
/// signale beaucoup de choses.
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

/// Le compte signalé, lu depuis `users/{uid}` — les administrateurs peuvent
/// lire n’importe quel profil, et personne ne peut les lister.
class ReportedAccount {
  const ReportedAccount({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.suspended = false,
    this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final bool suspended;
  final DateTime? createdAt;
}

/// `admins/{uid}` — qui détient le rôle back-office.
class AdminAccount {
  const AdminAccount({
    required this.id,
    required this.email,
    this.name,
    this.grantedAt,
  });

  final String id;
  final String email;
  final String? name;
  final DateTime? grantedAt;
}

/// Ce qu’un modérateur peut faire ensuite. Fonction pure, pour que l’écran et
/// les tests s’accordent avec ce que les règles accepteront.
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
}
