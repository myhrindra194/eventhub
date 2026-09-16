import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/extensions/context_x.dart';
import 'package:eventhub/core/media/camera_permission.dart';
import 'package:eventhub/core/widgets/app_button.dart';
import 'package:eventhub/core/widgets/app_sheet.dart';
import 'package:flutter/material.dart';

// Les textes restent privés à ce fichier : ils ne servent qu'à ce parcours,
// et les isoler ici évite de toucher au catalogue partagé des chaînes pour
// une poignée de phrases qu'aucun autre écran ne réutilise.
const _continueLabel = 'Continuer';
const _laterLabel = 'Plus tard';
const _openSettingsLabel = 'Ouvrir les réglages';

/// Ce que l'utilisateur s'apprête à autoriser : les textes changent, le
/// parcours reste le même.
enum MediaAccess {
  camera(
    rationaleTitle: 'Autoriser l’appareil photo',
    rationaleBody:
        'EventHub a besoin de l’appareil photo pour prendre votre photo de '
        'profil ou de couverture.',
    rationaleDetails:
        'La photo n’est envoyée qu’une fois que vous l’avez validée. L’accès '
        'sert aussi à scanner les billets si vous organisez des événements, '
        'et vous pouvez le retirer à tout moment dans les réglages de votre '
        'appareil.',
    blockedTitle: 'Accès à l’appareil photo refusé',
    blockedBody:
        'Pour prendre une photo, autorisez l’appareil photo pour EventHub dans '
        'les réglages de votre appareil.',
    blockedDetails:
        'Vous pouvez aussi choisir une image existante dans votre galerie.',
    deniedToast:
        'Sans accès à l’appareil photo, choisissez plutôt une image de votre '
        'galerie.',
    settingsUnavailableToast:
        'Impossible d’ouvrir les réglages. Autorisez l’appareil photo depuis '
        'les réglages de votre appareil.',
  ),
  photos(
    rationaleTitle: 'Autoriser l’accès à vos photos',
    rationaleBody:
        'EventHub a besoin d’accéder à vos photos pour importer votre photo de '
        'profil ou de couverture.',
    rationaleDetails:
        'Seule l’image que vous choisissez est envoyée, et seulement après '
        'votre validation. Vous pouvez retirer cet accès à tout moment dans '
        'les réglages de votre appareil.',
    blockedTitle: 'Accès à vos photos refusé',
    blockedBody:
        'Pour importer une photo, autorisez l’accès aux photos pour EventHub '
        'dans les réglages de votre appareil.',
    blockedDetails:
        'Vous pouvez aussi prendre une nouvelle photo avec l’appareil photo.',
    deniedToast:
        'Sans accès à vos photos, prenez plutôt une photo avec l’appareil '
        'photo.',
    settingsUnavailableToast:
        'Impossible d’ouvrir les réglages. Autorisez l’accès aux photos depuis '
        'les réglages de votre appareil.',
  );

  const MediaAccess({
    required this.rationaleTitle,
    required this.rationaleBody,
    required this.rationaleDetails,
    required this.blockedTitle,
    required this.blockedBody,
    required this.blockedDetails,
    required this.deniedToast,
    required this.settingsUnavailableToast,
  });

  final String rationaleTitle;
  final String rationaleBody;
  final String rationaleDetails;
  final String blockedTitle;
  final String blockedBody;
  final String blockedDetails;
  final String deniedToast;
  final String settingsUnavailableToast;
}

/// Fait passer l'utilisateur par le parcours d'accès à la caméra et rend
/// `true` seulement si la caméra peut s'ouvrir.
///
/// Toute la décision vit dans [CameraAccessGate] ; cette fonction ne fait que
/// traduire chaque issue en interface : une feuille d'explication avant
/// l'invite système, un message court après un refus, une feuille de renvoi
/// vers les réglages quand l'accès est bloqué. Garder les deux séparés permet
/// de tester la logique sans monter de widget, et de changer l'habillage sans
/// risquer de casser la logique.
Future<bool> ensureCameraAccess(BuildContext context, CameraAccessGate gate) =>
    ensureMediaAccess(context, gate, MediaAccess.camera);

/// Même parcours pour la caméra ou la galerie ; seuls les textes changent.
Future<bool> ensureMediaAccess(
  BuildContext context,
  CameraAccessGate gate,
  MediaAccess access,
) async {
  final outcome = await gate.resolve(
    explain: () async {
      if (!context.mounted) return false;
      return _showRationaleSheet(context, access);
    },
  );
  if (!context.mounted) return false;

  switch (outcome) {
    case CameraAccessOutcome.granted:
      return true;
    case CameraAccessOutcome.dismissed:
      // « Plus tard » n'est pas un refus : aucun message, l'utilisateur
      // reviendra de lui-même.
      return false;
    case CameraAccessOutcome.denied:
      context.showToast(access.deniedToast);
      return false;
    case CameraAccessOutcome.blocked:
      if (!await _showBlockedSheet(context, access)) return false;
      final opened = await gate.openSettings();
      if (!opened && context.mounted) {
        context.showToast(
          access.settingsUnavailableToast,
          tone: AppTone.warning,
        );
      }
      // Même si les réglages s'ouvrent, la caméra ne s'ouvre pas au retour :
      // l'utilisateur relance le geste, ce qui revérifie l'état réel plutôt
      // que de supposer qu'il a bien activé l'accès.
      return false;
  }
}

/// L'explication qui précède l'invite système. Rend `true` pour
/// « Continuer » ; « Plus tard », la croix et le glissement valent `false`.
Future<bool> _showRationaleSheet(
  BuildContext context,
  MediaAccess access,
) async {
  final result = await showAppSheet<bool>(
    context: context,
    builder: (sheetContext) => _AccessSheet(
      title: access.rationaleTitle,
      body: access.rationaleBody,
      details: access.rationaleDetails,
      primaryLabel: _continueLabel,
      secondaryLabel: _laterLabel,
      sheetContext: sheetContext,
    ),
  );
  return result ?? false;
}

/// Le renvoi vers les réglages quand le système ne posera plus la question.
Future<bool> _showBlockedSheet(BuildContext context, MediaAccess access) async {
  final result = await showAppSheet<bool>(
    context: context,
    builder: (sheetContext) => _AccessSheet(
      title: access.blockedTitle,
      body: access.blockedBody,
      details: access.blockedDetails,
      primaryLabel: _openSettingsLabel,
      secondaryLabel: _laterLabel,
      sheetContext: sheetContext,
    ),
  );
  return result ?? false;
}

/// Les deux feuilles partagent la même anatomie que la feuille de
/// consentement : titre et conséquence en tête, précision en corps, deux
/// boutons texte empilés, l'action principale au-dessus.
class _AccessSheet extends StatelessWidget {
  const _AccessSheet({
    required this.title,
    required this.body,
    required this.details,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.sheetContext,
  });

  final String title;
  final String body;
  final String details;
  final String primaryLabel;
  final String secondaryLabel;

  /// Le contexte de la feuille elle-même : c'est lui qu'il faut dépiler, pas
  /// celui de l'écran qui l'a ouverte.
  final BuildContext sheetContext;

  @override
  Widget build(BuildContext context) {
    return AppSheet(
      title: title,
      subtitle: body,
      actions: [
        AppButton.primary(
          label: primaryLabel,
          onPressed: () => Navigator.of(sheetContext).pop(true),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton.secondary(
          label: secondaryLabel,
          onPressed: () => Navigator.of(sheetContext).pop(false),
        ),
      ],
      child: Text(
        details,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.5),
      ),
    );
  }
}
