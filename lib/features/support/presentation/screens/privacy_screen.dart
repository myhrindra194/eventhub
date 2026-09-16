import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/config/app_links.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/features/support/presentation/widgets/support_page.dart';
import 'package:flutter/material.dart';

/// Politique de confidentialité.
///
/// Écrite face au vrai modèle de données, pas à partir d’un modèle type :
/// chaque affirmation qu’on y lit est appliquée quelque part — `users/{uid}`
/// n’est lisible que par son propriétaire, la liste des participants n’expose
/// le nom et l’email qu’au seul organisateur de l’événement, la mesure
/// d’audience ne collecte rien avant le consentement (voir
/// `firebase/firestore.rules` et `AnalyticsConsent`). Si une règle change,
/// cette page est fausse tant qu’elle n’est pas mise à jour.
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
              'réservations, favoris, organisateurs suivis, inscriptions en '
              'liste d’attente, avis et signalements. Pour les organisateurs, '
              'la présentation publique, les événements publiés, leurs images '
              'et les entrées scannées. Les appareils sur lesquels vous '
              'acceptez les notifications.',
        ),
        NumberedSection(
          number: '02',
          title: 'Qui peut le voir',
          body:
              'Votre profil, vos favoris, vos abonnements, vos appareils et vos '
              'préférences sont privés : personne, pas même un organisateur, '
              'ne sait qui le suit. Quand vous réservez, votre nom et votre '
              "email deviennent visibles par l'organisateur de cet événement, "
              "et par lui seul — c'est la liste qu'il consulte à l'entrée. Les "
              'autres utilisateurs voient seulement votre prénom et l’initiale '
              'de votre nom parmi « qui y va ». Un avis est public, signé de '
              'votre nom. Un signalement est anonyme. Pour un organisateur, le '
              'nom et la présentation sont publics ; l’email ne l’est jamais.',
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
              'au bout de 30 jours, le journal de modération au bout d’un an. '
              "Une réservation annulée reste dans l'historique, pour que la "
              "jauge de l'organisateur reste cohérente. Un lien partagé "
              "affiche publiquement le titre, la date, le lieu, l'organisateur "
              'et les places restantes de l’événement — jamais ses inscrits.',
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
