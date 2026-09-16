import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:flutter/material.dart';

/// Ce que l'utilisateur a choisi dans la feuille des photos.
enum PhotoChoice { gallery, camera, remove }

/// Demande d'où vient la nouvelle image — ou s'il faut retirer l'actuelle.
///
/// Une feuille plutôt qu'un menu : trois options dont une destructive, avec
/// une phrase qui explique où finit l'image. [hasImage] masque le retrait
/// quand il n'y a rien à retirer, parce qu'une option désactivée dans une
/// liste de trois lignes ne fait qu'ajouter du bruit.
Future<PhotoChoice?> showPhotoSourceSheet(
  BuildContext context, {
  required bool cover,
  required bool hasImage,
}) => showAppSheet<PhotoChoice>(
  context: context,
  builder: (sheetContext) => AppSheet(
    title: cover ? AppStrings.profileCover : AppStrings.profilePhoto,
    subtitle: AppStrings.photoHelp,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Option(
          icon: Icons.photo_library_outlined,
          label: AppStrings.photoFromGallery,
          onTap: () => Navigator.of(sheetContext).pop(PhotoChoice.gallery),
        ),
        _Option(
          icon: Icons.photo_camera_outlined,
          label: AppStrings.photoFromCamera,
          onTap: () => Navigator.of(sheetContext).pop(PhotoChoice.camera),
        ),
        if (hasImage)
          _Option(
            icon: Icons.delete_outline_rounded,
            label: cover ? AppStrings.removeCover : AppStrings.removePhoto,
            destructive: true,
            onTap: () => Navigator.of(sheetContext).pop(PhotoChoice.remove),
          ),
      ],
    ),
  ),
);

class _Option extends StatelessWidget {
  const _Option({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final color = destructive ? t.danger.fg : t.textPrimary;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Couverture et photo de profil, éditables d'un geste.
///
/// Les deux images se règlent là où on les voit, et non dans deux lignes de
/// formulaire nommées « photo » et « couverture » : c'est la disposition
/// qu'ont retenue tous les réseaux où l'on a un profil, parce qu'on ne
/// choisit pas une image sans voir ce qu'elle donne une fois cadrée.
class ProfileImagesEditor extends StatelessWidget {
  const ProfileImagesEditor({
    required this.name,
    required this.photoUrl,
    required this.coverUrl,
    required this.onEditPhoto,
    required this.onEditCover,
    super.key,
  });

  final String name;
  final String? photoUrl;
  final String? coverUrl;
  final VoidCallback onEditPhoto;
  final VoidCallback onEditCover;

  static const _coverHeight = 104.0;
  static const _avatarSize = 84.0;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final cover = coverUrl ?? '';

    return SizedBox(
      // La moitié basse de l'avatar déborde sous la couverture : la hauteur
      // totale doit en tenir compte, sinon le débordement est rogné.
      height: _coverHeight + _avatarSize / 2,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: GestureDetector(
              onTap: onEditCover,
              child: Container(
                height: _coverHeight,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: t.surfaceSunken,
                  borderRadius: AppRadius.brButton,
                  border: Border.all(color: t.border),
                ),
                child: cover.isEmpty
                    ? Center(
                        child: Text(
                          AppStrings.addCover,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      )
                    : EventImage(imageUrl: cover, height: _coverHeight),
              ),
            ),
          ),
          Positioned(
            top: AppSpacing.sm,
            right: AppSpacing.sm,
            child: IconActionButton(
              icon: Icons.photo_camera_outlined,
              tooltip: cover.isEmpty
                  ? AppStrings.addCover
                  : AppStrings.changeCover,
              size: 34,
              background: t.glass,
              onPressed: onEditCover,
            ),
          ),
          Positioned(
            bottom: 0,
            child: GestureDetector(
              onTap: onEditPhoto,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: t.canvas,
                    ),
                    child: AppAvatar(
                      name: name,
                      imageUrl: photoUrl,
                      size: _avatarSize,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 2,
                    child: Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: t.brand,
                        shape: BoxShape.circle,
                        border: Border.all(color: t.canvas, width: 2),
                      ),
                      child: Icon(
                        Icons.photo_camera_outlined,
                        size: 14,
                        color: t.textOnBrand,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
