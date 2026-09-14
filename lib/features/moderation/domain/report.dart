import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/result/result.dart';

/// What can be reported. Wire values match `targetType` in firestore.rules.
enum ReportTarget {
  event('Événement'),
  user('Organisateur'),
  review('Avis');

  const ReportTarget(this.label);

  final String label;
}

/// Closed list, mirrored in firestore.rules: moderators triage by reason, so
/// a free-text reason would be a reason nobody can sort.
enum ReportReason {
  misleading(
    'misleading',
    'Informations trompeuses',
    'Date, lieu ou description qui ne correspondent pas à la réalité.',
  ),
  fraud(
    'fraud',
    'Arnaque',
    'Demande de paiement, faux événement, collecte de données personnelles.',
  ),
  inappropriate(
    'inappropriate',
    'Contenu inapproprié',
    'Propos ou images choquants, discriminatoires ou violents.',
  ),
  harassment('harassment', 'Harcèlement', 'Attaque visant une personne.'),
  spam('spam', 'Spam ou publicité', 'Promotion sans rapport, liens répétés.'),
  other('other', 'Autre motif', 'Expliquez en quelques mots ci-dessous.');

  const ReportReason(this.wire, this.label, this.description);

  final String wire;
  final String label;
  final String description;
}

/// Mirrored in firestore.rules (`reports` create).
abstract final class ReportPolicy {
  static const maxDetails = 2000;

  /// One report per account per target: the id is the uniqueness.
  static String composeId({
    required ReportTarget target,
    required String targetId,
    required String reporterId,
  }) => '${target.name}_${targetId}_$reporterId';

  static Result<void> validate({
    required String reporterId,
    required ReportTarget target,
    required String targetId,
    required ReportReason? reason,
    required String details,
  }) {
    if (targetId.isEmpty) {
      return const Err(ValidationFailure(message: 'Contenu introuvable.'));
    }
    final isOwn = switch (target) {
      ReportTarget.user => targetId == reporterId,
      // Review ids are `<eventId>_<authorId>`.
      ReportTarget.review => targetId.endsWith('_$reporterId'),
      ReportTarget.event => false,
    };
    if (isOwn) {
      return const Err(
        BusinessRuleFailure(
          rule: BusinessRule.cannotReportSelf,
          message: 'Vous ne pouvez pas signaler votre propre contenu.',
        ),
      );
    }
    if (reason == null) {
      return const Err(ValidationFailure(message: 'Choisissez un motif.'));
    }
    final text = details.trim();
    if (reason == ReportReason.other && text.isEmpty) {
      return const Err(
        ValidationFailure(message: 'Précisez le motif en quelques mots.'),
      );
    }
    if (text.length > maxDetails) {
      return const Err(ValidationFailure(message: '2 000 caractères maximum.'));
    }
    return const Ok(null);
  }
}
