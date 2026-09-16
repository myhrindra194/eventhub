import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/result/result.dart';

/// Ce qui peut être signalé. Les noms correspondent à l’enum `report_target`
/// de Postgres.
enum ReportTarget {
  event('Événement'),
  user('Organisateur'),
  review('Avis');

  const ReportTarget(this.label);

  final String label;
}

/// Liste fermée, l’enum `report_reason` : les modérateurs trient par motif, et
/// un motif en texte libre serait un motif que personne ne peut trier.
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

/// Contrôles locaux avant l’insertion d’un signalement ;
/// `reports_before_insert` les rejoue tous avec les faits que le client ne
/// peut pas voir (qui a écrit un avis).
abstract final class ReportPolicy {
  static const maxDetails = 2000;

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
    // Seul un identifiant de compte dit à qui il appartient. Un identifiant
    // d’avis est un uuid opaque : la liste des avis masque l’action de
    // signalement sur son propre avis, et le trigger répond
    // `cannotReportSelf` si on l’atteint malgré tout.
    final isOwn = target == ReportTarget.user && targetId == reporterId;
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
