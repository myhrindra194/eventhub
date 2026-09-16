import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/extensions/context_x.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/media/device_image_picker.dart';
import 'package:eventhub/core/media/image_kind.dart';
import 'package:eventhub/core/media/media_providers.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/auth/application/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Couverture d'un événement : un fichier importé depuis l'appareil, avec
/// son aperçu.
///
/// Le modèle est celui d'Eventbrite et de Luma : l'organisateur choisit une
/// image, elle part aussitôt vers Cloudinary, et l'aperçu montre l'image
/// **hébergée** — donc exactement ce que verront les participants, recadrée
/// en 16:9. Tant qu'il n'y en a pas, l'aperçu montre le visuel généré que
/// l'événement conservera, pour qu'un événement sans couverture n'ait jamais
/// l'air cassé.
///
/// Le champ ne tient pas d'état propre : [imageUrl] vient du formulaire et
/// chaque changement lui est rendu par [onChanged]. Le formulaire sait ainsi
/// qu'un envoi est en cours ([onUploadingChanged]) et refuse de publier un
/// événement dont l'affiche n'est pas encore arrivée.
class EventCoverField extends ConsumerStatefulWidget {
  const EventCoverField({
    required this.imageUrl,
    required this.onChanged,
    required this.seed,
    super.key,
    this.onUploadingChanged,
    this.errorText,
  });

  final String? imageUrl;
  final ValueChanged<String?> onChanged;
  final ValueChanged<bool>? onUploadingChanged;

  /// Graine du visuel généré de repli (l'id de l'événement, ou son titre).
  final String seed;

  /// Une erreur venue du serveur, rapportée sur ce champ.
  final String? errorText;

  @override
  ConsumerState<EventCoverField> createState() => _EventCoverFieldState();
}

class _EventCoverFieldState extends ConsumerState<EventCoverField> {
  bool _uploading = false;

  void _setUploading(bool value) {
    setState(() => _uploading = value);
    widget.onUploadingChanged?.call(value);
  }

  Future<void> _import() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    _setUploading(true);
    final result = await ref
        .read(imageUploadFlowProvider)
        .run(
          kind: ImageKind.eventCover,
          // La galerie seulement : une affiche se prépare, elle ne se prend
          // pas en photo depuis le formulaire — et le bureau comme le web
          // n'ont de toute façon pas d'appareil photo à proposer.
          source: PhotoSource.gallery,
          ownerId: user.id,
        );
    if (!mounted) return;
    _setUploading(false);

    switch (result) {
      case null:
        return;
      case Ok(:final value):
        widget.onChanged(value.url);
      case Err(:final failure):
        context.showFailure(failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final url = widget.imageUrl;
    final hasImage = url != null && url.isNotEmpty;
    final available = ref.watch(imageUploadFlowProvider).isAvailable;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: AppRadius.brButton,
          child: DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              borderRadius: AppRadius.brButton,
              border: Border.all(
                color: widget.errorText == null ? t.border : t.danger.fg,
              ),
            ),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  EventImage(
                    // Clé sur l'URL : une nouvelle image remplace l'aperçu
                    // au lieu de fondre depuis la précédente.
                    key: ValueKey(url),
                    imageUrl: hasImage ? url : null,
                    seed: widget.seed,
                  ),
                  if (_uploading)
                    Semantics(
                      label: AppStrings.imageUploading,
                      liveRegion: true,
                      child: ColoredBox(
                        color: t.canvas.withValues(alpha: 0.6),
                        child: Center(
                          child: SizedBox.square(
                            dimension: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: t.brand,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (available)
          Row(
            children: [
              AppButton.tonal(
                label: hasImage
                    ? AppStrings.changeImage
                    : AppStrings.uploadImage,
                loadingLabel: AppStrings.imageUploading,
                isLoading: _uploading,
                onPressed: _uploading ? null : _import,
              ),
              if (hasImage && !_uploading) ...[
                const SizedBox(width: AppSpacing.sm),
                TextButton(
                  onPressed: () => widget.onChanged(null),
                  child: const Text('Retirer'),
                ),
              ],
            ],
          ),
        if (widget.errorText case final error?) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            error,
            style: context.textTheme.bodySmall?.copyWith(color: t.danger.fg),
          ),
        ],
        const SizedBox(height: AppSpacing.xs),
        Text(
          !available
              ? AppStrings.imageUploadUnavailable
              : hasImage
              ? 'JPEG, PNG ou WebP, 10 Mo au plus. Recadrée en 16:9 à l’affichage.'
              : 'Sans image, l’événement garde ce visuel généré.',
          style: context.textTheme.bodySmall?.copyWith(color: t.textSecondary),
        ),
      ],
    );
  }
}
