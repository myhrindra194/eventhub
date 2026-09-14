import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/config/app_links.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/features/support/presentation/widgets/support_page.dart';
import 'package:flutter/material.dart';

/// Privacy notice.
///
/// Written against the real data model, not a template: every statement
/// here is enforced somewhere — `users/{uid}` is readable by its owner only,
/// the participant list exposes name and email to the event's organizer
/// only (see `firebase/firestore.rules`). If a rule changes, this page is
/// wrong until it is updated.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SupportPage(
      title: AppStrings.privacy,
      eyebrow: 'Mise à jour le 1er septembre 2026',
      headline: 'Ce que nous savons de vous, et pourquoi.',
      lead:
          'La version courte : le strict nécessaire pour réserver et '
          "organiser. Rien n'est vendu, rien ne sert à de la publicité.",
      children: [
        NumberedSection(
          number: '01',
          title: 'Ce que nous collectons',
          body:
              'Votre nom, votre adresse email et votre rôle, donnés à '
              "l'inscription. Vos réservations : l'événement, la date, le "
              'statut. Pour les organisateurs, les événements publiés et '
              'leurs images.',
        ),
        NumberedSection(
          number: '02',
          title: 'Qui peut le voir',
          body:
              'Votre profil est privé : vous seul pouvez le lire. Quand vous '
              'réservez, votre nom et votre email deviennent visibles par '
              "l'organisateur de cet événement, et par lui seul — c'est la "
              "liste qu'il consulte à l'entrée.",
        ),
        NumberedSection(
          number: '03',
          title: 'Où c’est stocké',
          body:
              'Sur Firebase (Google Cloud) : authentification, base Firestore '
              'et stockage des images. Les accès sont vérifiés côté serveur '
              'par des règles de sécurité, pas seulement par l’application.',
        ),
        NumberedSection(
          number: '04',
          title: 'Combien de temps',
          body:
              'Tant que votre compte existe. Une réservation annulée reste '
              "dans l'historique, pour que la jauge de l'organisateur reste "
              'cohérente.',
        ),
        NumberedSection(
          number: '05',
          title: 'Vos droits',
          body:
              'Accès, rectification, suppression : écrivez à '
              '${AppLinks.supportEmail}. Votre nom se modifie directement '
              'depuis le profil. La suppression du compte est traitée à la '
              'main, car vos réservations et événements doivent être '
              'réconciliés d’abord.',
        ),
        SizedBox(height: AppSpacing.sm),
        SupportContactCard(),
      ],
    );
  }
}
