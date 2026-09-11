import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/events/application/event_form_controller.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Cover picker.
///
/// Three states: an inviting dashed drop zone, a preview with a "changer"
/// affordance, and an error state when the file is too large. The size
/// limit is enforced here *and* stated up front, because a rejection after
/// a long upload is the worst possible moment to learn about it — and the
/// same 5 MB ceiling is re-enforced by the Storage rules, so the client
/// check is a courtesy, not the guarantee.
class EventImagePicker extends StatefulWidget {
  const EventImagePicker({
    required this.onPicked,
    super.key,
    this.currentUrl,
    this.pending,
  });

  final String? currentUrl;
  final PendingImage? pending;
  final ValueChanged<PendingImage> onPicked;

  static const maxBytes = 5 * 1024 * 1024;
  static const _maxDimension = 1600.0;
  static const _quality = 85;

  @override
  State<EventImagePicker> createState() => _EventImagePickerState();
}

class _EventImagePickerState extends State<EventImagePicker> {
  bool _tooLarge = false;

  Future<void> _pick() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      // Downscaling client-side keeps most uploads well under the cap and
      // saves the user's data plan.
      maxWidth: EventImagePicker._maxDimension,
      maxHeight: EventImagePicker._maxDimension,
      imageQuality: EventImagePicker._quality,
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();
    if (bytes.length > EventImagePicker.maxBytes) {
      setState(() => _tooLarge = true);
      return;
    }
    setState(() => _tooLarge = false);
    widget.onPicked(
      PendingImage(bytes: bytes, contentType: file.mimeType ?? 'image/jpeg'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final pending = widget.pending;
    final hasImage =
        pending != null || (widget.currentUrl?.isNotEmpty ?? false);

    return GestureDetector(
      onTap: _pick,
      child: SizedBox(
        height: 190,
        child: hasImage
            ? Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: AppRadius.brLg,
                    child: pending != null
                        ? Image.memory(pending.bytes, fit: BoxFit.cover)
                        : EventImage(imageUrl: widget.currentUrl),
                  ),
                  Positioned(
                    right: AppSpacing.md,
                    bottom: AppSpacing.md,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: t.brand,
                        borderRadius: AppRadius.brPill,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.photo_camera_rounded,
                            size: 13,
                            color: t.textOnBrand,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            AppStrings.changeImage,
                            style: text.labelSmall?.copyWith(
                              color: t.textOnBrand,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : CustomPaint(
                painter: _DashedBorderPainter(
                  color: _tooLarge ? t.danger.fg : t.borderStrong,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: _tooLarge ? t.danger.bg : t.surfaceSunken,
                    borderRadius: AppRadius.brLg,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconTile(
                        icon: _tooLarge
                            ? Icons.error_outline_rounded
                            : Icons.add_photo_alternate_outlined,
                        size: 52,
                        color: _tooLarge ? t.danger.fg : t.brand,
                        background: _tooLarge ? t.danger.bg : t.brandSoft,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        _tooLarge
                            ? 'Fichier trop volumineux (5 Mo max)'
                            : AppStrings.uploadImage,
                        style: text.titleSmall?.copyWith(
                          color: _tooLarge ? t.danger.fg : t.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        _tooLarge
                            ? 'Choisissez une image plus légère'
                            : 'Touchez pour parcourir vos photos',
                        style: text.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(AppRadius.lg),
    );
    final path = Path()..addRRect(rrect);

    const dash = 7.0;
    const gap = 5.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + dash), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}
