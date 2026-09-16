import 'package:cached_network_image/cached_network_image.dart';
import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/media/cloudinary_url.dart';
import 'package:eventhub/core/utils/image_data_url.dart';
import 'package:eventhub/core/widgets/app_skeleton.dart';
import 'package:flutter/material.dart';

/// Le visuel d'un événement, avec un repli dessiné.
///
/// Un événement sans image n'est pas un état d'erreur : plutôt qu'un carré
/// gris portant un glyphe d'image brisée, on rend un **dégradé
/// déterministe** dérivé de [seed], l'identifiant de l'événement. Deux
/// conséquences qui comptent à l'échelle d'un catalogue : un fil d'événements
/// sans photo garde l'air intentionnel, et le même événement conserve les
/// mêmes couleurs partout où il apparaît.
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

  /// Chaîne stable — identifiant ou titre de l'événement — qui détermine le
  /// dégradé de repli.
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

  /// L'`ImageProvider` correspondant à une URL du produit, quelle que soit sa
  /// provenance — Cloudinary, image héritée portée par le document (`data:`)
  /// ou lien distant. Renvoie `null` quand il n'y a rien à afficher, ce qui
  /// laisse l'appelant poser son propre repli.
  ///
  /// [width] est la largeur **physique** voulue ; sans elle, une image
  /// Cloudinary est servie au palier le plus large, ce qui convient à un
  /// fond plein écran mais gaspille de la bande passante partout ailleurs.
  static ImageProvider? providerFor(String? url, {int? width}) {
    if (url == null || url.isEmpty) return null;
    if (ImageDataUrl.isDataUrl(url)) {
      final bytes = ImageDataUrl.decode(url);
      return bytes == null ? null : MemoryImage(bytes);
    }
    return CachedNetworkImageProvider(
      CloudinaryUrl.sized(url, width: width ?? CloudinaryUrl.widths.last),
    );
  }

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
    if (url == null || url.isEmpty) {
      return ClipRRect(borderRadius: borderRadius, child: _fallback(context));
    }

    // Deux provenances derrière une seule chaîne : une URL `data:` héritée
    // (photo embarquée dans le document avant Cloudinary) et le réseau.
    if (ImageDataUrl.isDataUrl(url)) {
      final bytes = ImageDataUrl.decode(url);
      return ClipRRect(
        borderRadius: borderRadius,
        child: bytes == null
            ? _fallback(context)
            : Image.memory(bytes, height: height, width: width, fit: fit),
      );
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // La largeur réellement occupée décide de la variante téléchargée :
          // la même affiche part en 640 px dans une carte de téléphone et en
          // 1 920 px dans la fiche d'un écran de bureau Retina.
          final logicalWidth = constraints.hasBoundedWidth
              ? constraints.maxWidth
              : (height ?? 200) * 16 / 9;
          final physical = CloudinaryUrl.bucketFor(
            logicalWidth,
            MediaQuery.devicePixelRatioOf(context),
          );
          return CachedNetworkImage(
            imageUrl: CloudinaryUrl.sized(url, width: physical),
            height: height,
            width: width,
            fit: fit,
            fadeInDuration: AppMotion.medium,
            placeholder: (_, __) => Skeleton(height: height ?? 200, radius: 0),
            errorWidget: (context, _, __) => _fallback(context),
          );
        },
      ),
    );
  }
}
