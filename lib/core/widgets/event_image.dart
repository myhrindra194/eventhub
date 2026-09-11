import 'package:cached_network_image/cached_network_image.dart';
import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/utils/in_memory_images.dart';
import 'package:eventhub/core/widgets/app_skeleton.dart';
import 'package:flutter/material.dart';

/// Event artwork with a designed fallback.
///
/// An event without a cover is not an error state: rather than a grey box
/// with a broken-image glyph, we render a **deterministic gradient** derived
/// from [seed] (the event id). Two consequences that matter at scale:
/// a feed of image-less events still looks intentional, and the same event
/// keeps the same colours everywhere it appears.
class EventImage extends StatelessWidget {
  const EventImage({
    super.key,
    this.imageUrl,
    this.height,
    this.width = double.infinity,
    this.borderRadius = BorderRadius.zero,
    this.seed,
    this.icon = Icons.local_activity_rounded,
    this.fit = BoxFit.cover,
  });

  final String? imageUrl;
  final double? height;
  final double? width;
  final BorderRadius borderRadius;

  /// Stable string (event id, title) used to pick the fallback gradient.
  final String? seed;
  final IconData icon;
  final BoxFit fit;

  static const _gradients = <List<Color>>[
    [AppPalette.iris500, AppPalette.iris800],
    [AppPalette.violet500, AppPalette.iris700],
    [AppPalette.sky500, AppPalette.iris600],
    [AppPalette.teal500, AppPalette.sky600],
    [AppPalette.ember500, AppPalette.rose600],
    [AppPalette.fuchsia500, AppPalette.violet500],
  ];

  List<Color> get _fallbackGradient {
    final key = seed ?? imageUrl ?? '';
    if (key.isEmpty) return _gradients.first;
    final hash = key.codeUnits.fold<int>(11, (a, c) => (a * 33 + c) & 0xFFFF);
    return _gradients[hash % _gradients.length];
  }

  Widget _fallback(BuildContext context) {
    final colors = _fallbackGradient;
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 40, color: Colors.white.withValues(alpha: 0.28)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    final memoryBytes = InMemoryImages.isMemoryUrl(url)
        ? InMemoryImages.get(url!)
        : null;

    return ClipRRect(
      borderRadius: borderRadius,
      child: url == null || url.isEmpty
          ? _fallback(context)
          : memoryBytes != null
          ? Image.memory(memoryBytes, height: height, width: width, fit: fit)
          : CachedNetworkImage(
              imageUrl: url,
              height: height,
              width: width,
              fit: fit,
              fadeInDuration: AppMotion.medium,
              placeholder: (_, __) =>
                  Skeleton(height: height ?? 200, radius: 0),
              errorWidget: (context, _, __) => _fallback(context),
            ),
    );
  }
}
