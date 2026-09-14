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
/// only, analytics collect nothing before consent (see
/// `firebase/firestore.rules` and `AnalyticsConsent`). If a rule changes,
/// this page is wrong until it is updated.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SupportPage(
      title: AppStrings.privacy,
      eyebrow: 'Mise à jour le 14 septembre 2026',
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
              "l'inscription (ou par Google si vous vous connectez avec). Vos "
              'réservations, favoris, inscriptions en liste d’attente et avis. '
              'Pour les organisateurs, les événements publiés, leurs images et '
              'les entrées scannées. Les appareils sur lesquels vous acceptez '
              'les notifications.',
        ),
        NumberedSection(
          number: '02',
          title: 'Qui peut le voir',
          body:
              'Votre profil, vos favoris, vos appareils et vos préférences '
              'sont privés. Quand vous réservez, votre nom et votre email '
              "deviennent visibles par l'organisateur de cet événement, et par "
              "lui seul — c'est la liste qu'il consulte à l'entrée. Un avis "
              'est public, signé de votre nom.',
        ),
        NumberedSection(
          number: '03',
          title: 'Où c’est stocké',
          body:
              'Sur Firebase (Google Cloud) : authentification, base Firestore, '
              'stockage des images et fonctions serveur. Les accès sont '
              'vérifiés côté serveur par des règles de sécurité, et App Check '
              'limite les appels aux applications authentiques.',
        ),
        NumberedSection(
          number: '04',
          title: 'Mesure d’audience et plantages',
          body:
              'Avec votre accord seulement, Firebase Analytics mesure les '
              'écrans consultés et quelques actions, rattachés à un '
              'identifiant technique. Les rapports de plantage (Crashlytics) '
              'servent à corriger les erreurs ; ils contiennent l’identifiant '
              'technique du compte, jamais son contenu. L’accord se retire '
              'dans les Paramètres.',
        ),
        NumberedSection(
          number: '05',
          title: 'Combien de temps',
          body:
              'Tant que votre compte existe. Les notifications sont effacées '
              'au bout de 30 jours. Une réservation annulée reste dans '
              "l'historique, pour que la jauge de l'organisateur reste "
              'cohérente.',
        ),
        NumberedSection(
          number: '06',
          title: 'Vos droits',
          body:
              'Accès, rectification : votre nom se modifie depuis le profil ; '
              'pour le reste, écrivez à ${AppLinks.supportEmail}. Suppression : '
              'Paramètres → Supprimer mon compte. Vos données sont effacées, '
              'vos réservations à venir annulées et vos avis anonymisés.',
        ),
        SizedBox(height: AppSpacing.sm),
        SupportContactCard(),
      ],
    );
  }
}
