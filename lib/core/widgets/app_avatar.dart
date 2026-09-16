import 'package:cached_network_image/cached_network_image.dart';
import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/media/cloudinary_url.dart';
import 'package:eventhub/core/utils/image_data_url.dart';
import 'package:flutter/material.dart';

/// Avatar d’initiales avec un dégradé **déterministe**.
///
/// La paire de teintes est dérivée du nom : la même personne reçoit donc
/// toujours les mêmes couleurs dans toute l’app (fil, billet, liste des
/// participants). C’est cette constance qui fait d’un avatar un repère
/// d’identité plutôt qu’une décoration — et cela ne coûte rien face au
/// stockage d’une photo.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    required this.name,
    super.key,
    this.size = 40,
    this.imageUrl,
    this.showRing = false,
  });

  final String name;
  final double size;
  final String? imageUrl;
  final bool showRing;

  static const _palettes = <List<Color>>[
    [AppPalette.iris400, AppPalette.iris600],
    [AppPalette.violet400, AppPalette.fuchsia500],
    [AppPalette.sky400, AppPalette.iris500],
    [AppPalette.teal400, AppPalette.mint600],
    [AppPalette.ember400, AppPalette.rose500],
    [AppPalette.amber400, AppPalette.ember600],
  ];

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  List<Color> get _gradient {
    if (name.isEmpty) return _palettes.first;
    final hash = name.codeUnits.fold<int>(
      7,
      (acc, c) => (acc * 31 + c) & 0xFFFF,
    );
    return _palettes[hash % _palettes.length];
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final colors = _gradient;

    Widget avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      child: _picture(context) ?? _label(context),
    );

    if (showRing) {
      avatar = Container(
        padding: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: t.brand, width: 2),
        ),
        child: avatar,
      );
    }
    return avatar;
  }

  /// La photo, si le compte en a une.
  ///
  /// Deux provenances possibles, et une seule chaîne pour les décrire : une
  /// URL `https:` (Cloudinary, ou un lien plus ancien) ou une URL `data:`
  /// (photo embarquée dans le profil avant Cloudinary). Dans les deux cas un
  /// échec retombe sur les initiales, qui restent une identité lisible.
  Widget? _picture(BuildContext context) {
    final url = imageUrl;
    if (url == null || url.isEmpty) return null;

    if (ImageDataUrl.isDataUrl(url)) {
      final bytes = ImageDataUrl.decode(url);
      if (bytes == null) return null;
      return Image.memory(
        bytes,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _label(context),
      );
    }

    // Un avatar de 40 px n'a pas à télécharger la photo de 1 024 px envoyée
    // par l'utilisateur : on demande un carré centré sur le visage, au palier
    // qui couvre la densité de l'écran.
    final side = CloudinaryUrl.bucketFor(
      size,
      MediaQuery.devicePixelRatioOf(context),
    );
    return Image(
      image: CachedNetworkImageProvider(
        CloudinaryUrl.sized(url, width: side, square: true),
      ),
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _label(context),
    );
  }

  Widget _label(BuildContext context) => Text(
    _initials,
    style: Theme.of(context).textTheme.titleMedium?.copyWith(
      color: Colors.white,
      fontSize: size * 0.38,
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
    ),
  );
}

/// Avatars superposés avec une pastille de dépassement « +n » — l’affordance
/// standard du « qui d’autre vient ». La preuve sociale est le plus fort
/// levier de conversion sur une carte d’événement : c’est donc un composant
/// de premier rang.
class AvatarStack extends StatelessWidget {
  const AvatarStack({
    required this.names,
    super.key,
    this.size = 28,
    this.max = 4,
    this.overlap = 0.34,
  });

  final List<String> names;
  final double size;
  final int max;
  final double overlap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final shown = names.take(max).toList();
    final extra = names.length - shown.length;
    final step = size * (1 - overlap);

    return SizedBox(
      height: size,
      width: shown.isEmpty
          ? 0
          : step * (shown.length - 1) + size + (extra > 0 ? step : 0),
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(
              left: i * step,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: t.canvas, width: 2),
                ),
                child: AppAvatar(name: shown[i], size: size),
              ),
            ),
          if (extra > 0)
            Positioned(
              left: shown.length * step,
              child: Container(
                width: size,
                height: size,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: t.surfaceSunken,
                  border: Border.all(color: t.canvas, width: 2),
                ),
                child: Text(
                  '+$extra',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: t.textSecondary,
                    letterSpacing: 0,
                    fontSize: size * 0.32,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
