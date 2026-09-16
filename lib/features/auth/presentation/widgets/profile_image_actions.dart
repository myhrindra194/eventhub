import 'package:eventhub/core/extensions/context_x.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/media/camera_access_prompt.dart';
import 'package:eventhub/core/media/camera_permission.dart';
import 'package:eventhub/core/media/device_image_picker.dart';
import 'package:eventhub/core/media/image_kind.dart';
import 'package:eventhub/core/media/media_providers.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/auth/application/auth_controller.dart';
import 'package:eventhub/features/auth/application/auth_providers.dart';
import 'package:eventhub/features/auth/presentation/widgets/profile_images_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Le choix fait dans la feuille « photo », une fois l'accès vérifié.
///
/// `null` : l'utilisateur a renoncé, ou l'accès a été refusé (la raison est
/// déjà affichée par le parcours d'autorisation).
Future<PhotoChoice?> choosePhotoSource(
  BuildContext context,
  WidgetRef ref, {
  required bool cover,
  required bool hasImage,
}) async {
  final flow = ref.read(imageUploadFlowProvider);
  if (!flow.isAvailable && !hasImage) {
    context.showToast(AppStrings.imageUploadUnavailable);
    return null;
  }
  final choice = await showPhotoSourceSheet(
    context,
    cover: cover,
    hasImage: hasImage,
    canUpload: flow.isAvailable,
  );
  if (choice == null || choice == PhotoChoice.remove || !context.mounted) {
    return choice;
  }

  // L'autorisation se demande *avant* d'ouvrir la caméra ou la galerie, avec
  // une explication propre à chacune : l'utilisateur sait ce qu'il accorde,
  // et pourquoi, au moment où il fait le geste.
  final allowed = choice == PhotoChoice.camera
      ? await ensureMediaAccess(
          context,
          ref.read(cameraAccessGateProvider),
          MediaAccess.camera,
        )
      : await ensureMediaAccess(
          context,
          ref.read(photoLibraryAccessGateProvider),
          MediaAccess.photos,
        );
  return allowed ? choice : null;
}

/// Change la photo de profil ou la couverture **depuis Profil**, et
/// l'enregistre aussitôt.
///
/// L'écran « Modifier mon profil » garde son parcours avec validation, parce
/// que l'image y voisine le nom et la présentation. Ici, le geste est isolé :
/// toucher sa photo, en choisir une autre, la voir en place — comme sur
/// Instagram ou WhatsApp. Demander en plus un « Enregistrer » pour une seule
/// image serait une étape sans raison d'être.
///
/// [onUploading] permet à l'en-tête de voiler l'image pendant l'envoi.
Future<void> changeProfileImage(
  BuildContext context,
  WidgetRef ref, {
  required bool cover,
  required ValueChanged<bool> onUploading,
}) async {
  final user = ref.read(currentUserProvider);
  if (user == null) return;
  final current = cover ? user.coverUrl : user.photoUrl;
  final choice = await choosePhotoSource(
    context,
    ref,
    cover: cover,
    hasImage: current != null && current.isNotEmpty,
  );
  if (choice == null || !context.mounted) return;

  String? newUrl;
  if (choice != PhotoChoice.remove) {
    onUploading(true);
    final uploaded = await ref
        .read(imageUploadFlowProvider)
        .run(
          kind: cover ? ImageKind.profileCover : ImageKind.avatar,
          source: choice == PhotoChoice.camera
              ? PhotoSource.camera
              : PhotoSource.gallery,
          ownerId: user.id,
        );
    if (!context.mounted) return;
    switch (uploaded) {
      case null:
        onUploading(false);
        return;
      case Err(:final failure):
        onUploading(false);
        context.showFailure(failure);
        return;
      case Ok(:final value):
        newUrl = value.url;
    }
  }

  final saved = await ref
      .read(authControllerProvider.notifier)
      .updateProfile(
        name: user.name,
        bio: user.isOrganizer ? user.bio : null,
        photoUrl: cover ? user.photoUrl : newUrl,
        coverUrl: cover ? newUrl : user.coverUrl,
        updatePhotos: true,
      );
  onUploading(false);
  if (!context.mounted) return;
  switch (saved) {
    case Ok():
      context.showSuccess(
        choice == PhotoChoice.remove
            ? (cover ? 'Couverture retirée.' : AppStrings.photoRemoved)
            : (cover ? AppStrings.coverUpdated : AppStrings.photoUpdated),
      );
    case Err(:final failure):
      context.showFailure(failure);
  }
}
