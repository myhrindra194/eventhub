import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/support/presentation/widgets/support_page.dart';
import 'package:flutter/material.dart';

/// Help centre.
///
/// Grouped by the moment a question comes up — booking, organising, the
/// account — rather than alphabetically. Every answer describes what the
/// product *does* (the rules live in `ReservationPolicy` / `EventPolicy`),
/// so this page has to change when those policies do.
class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  static const _booking = [
    FaqEntry(
      'Comment réserver une place ?',
      "Ouvrez la fiche de l'événement et touchez « Réserver ma place ». La "
          'place est retirée du stock au même instant pour tout le monde : si '
          'le bouton était actif, elle est à vous.',
    ),
    FaqEntry(
      'Puis-je réserver plusieurs places ?',
      'Non. Une réservation par personne et par événement — c’est ce qui '
          "permet à l'organisateur d'avoir une liste d'invités fiable.",
    ),
    FaqEntry(
      'Comment annuler ?',
      "Depuis la fiche de l'événement, touchez « Annuler ». La place revient "
          'immédiatement dans le stock, et vous pouvez réserver de nouveau '
          'tant qu’il en reste.',
    ),
    FaqEntry(
      'Où est mon billet ?',
      'Onglet « Billets ». Touchez un billet pour afficher son QR code, et '
          'le code à lire à voix haute si le scan ne passe pas.',
    ),
  ];

  static const _organizing = [
    FaqEntry(
      'Pourquoi ne puis-je pas réduire la capacité ?',
      'La capacité ne peut pas descendre sous le nombre de places déjà '
          "réservées : on ne retire pas une place à quelqu'un qui l'a obtenue.",
    ),
    FaqEntry(
      'Pourquoi ne puis-je pas supprimer mon événement ?',
      'Un événement qui a au moins une réservation ne peut pas être '
          'supprimé : des personnes comptent sur leur billet. Modifiez-le '
          '(date, lieu, description) ; la suppression redevient possible '
          'quand plus aucune place n’est réservée.',
    ),
    FaqEntry(
      'Comment récupérer la liste des participants ?',
      'Écran « Participants », puis « Exporter la liste ». Un fichier CSV '
          '(séparateur point-virgule, lisible tel quel par Excel et Numbers) '
          'est copié dans le presse-papiers.',
    ),
  ];

  static const _account = [
    FaqEntry(
      'Puis-je changer de rôle ?',
      'Non. Le rôle détermine votre espace et vos données. Pour organiser '
          'et participer, utilisez deux comptes avec deux adresses.',
    ),
    FaqEntry(
      "J'ai oublié mon mot de passe.",
      'Sur l’écran de connexion, « Mot de passe oublié ? ». Le lien arrive '
          'en moins d’une minute ; pensez à vérifier les spams.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return const SupportPage(
      title: AppStrings.helpCenter,
      eyebrow: 'Aide',
      headline: 'Les réponses courtes aux questions qui reviennent.',
      lead:
          "Classées par moment d'usage. Si la vôtre n'y est pas, écrivez-nous "
          ': chaque message est lu par une personne.',
      children: [
        SectionLabel('Réserver'),
        SizedBox(height: AppSpacing.sm),
        FaqGroup(entries: _booking),
        SizedBox(height: AppSpacing.xxxl),
        SectionLabel('Organiser'),
        SizedBox(height: AppSpacing.sm),
        FaqGroup(entries: _organizing),
        SizedBox(height: AppSpacing.xxxl),
        SectionLabel('Compte'),
        SizedBox(height: AppSpacing.sm),
        FaqGroup(entries: _account),
        SizedBox(height: AppSpacing.xxxl),
        SupportContactCard(),
      ],
    );
  }
}
