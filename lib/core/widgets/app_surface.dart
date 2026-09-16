import 'dart:ui';

import 'package:eventhub/app/theme/theme.dart';
import 'package:flutter/material.dart';

/// La primitive conteneur unique du design system.
///
/// Tout ce qui est « une boîte avec du contenu dessus » — cartes, tuiles,
/// panneaux, lignes de liste — est une [AppSurface]. La cohérence du rayon et
/// du filet est ainsi acquise, et un changement de design tient en une seule
/// édition ici.
///
/// Il n'y a pas de niveau d'élévation : le produit ne porte aucune ombre. Une
/// surface se détache de son fond par sa couleur et son filet, ce qui reste
/// lisible dans les deux thèmes là où une ombre noire s'effondre sur fond
/// sombre.
class AppSurface extends StatelessWidget {
  const AppSurface({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.margin,
    this.radius = AppRadius.xl,
    this.color,
    this.borderColor,
    this.gradient,
    this.onTap,
    this.onLongPress,
    this.clip = true,
    this.width,
    this.height,
  });

  /// Variante sans marge intérieure, pour les cartes menées par une image
  /// qui gèrent elles-mêmes leurs retraits.
  const AppSurface.bare({
    required this.child,
    super.key,
    this.margin,
    this.radius = AppRadius.xl,
    this.color,
    this.borderColor,
    this.gradient,
    this.onTap,
    this.onLongPress,
    this.clip = true,
    this.width,
    this.height,
  }) : padding = EdgeInsets.zero;

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final Color? color;
  final Color? borderColor;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool clip;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final br = BorderRadius.circular(radius);

    Widget content = Padding(padding: padding, child: child);

    if (onTap != null || onLongPress != null) {
      content = Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: br,
          child: content,
        ),
      );
    }

    return Container(
      width: width,
      height: height,
      margin: margin,
      clipBehavior: clip ? Clip.antiAlias : Clip.none,
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? t.surface) : null,
        gradient: gradient,
        borderRadius: br,
        border: Border.all(color: borderColor ?? t.border),
      ),
      child: content,
    );
  }
}

/// Panneau translucide et flouté. Réservé à ce qui doit laisser voir le
/// contenu situé dessous — feuilles, barres flottantes, calques posés sur une
/// photo. Le flou coûte cher : ne l'employez pas pour une carte ordinaire.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
    this.radius = AppRadius.xxl,
    this.color,
    this.blur = 22,
    this.showBorder = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final double blur;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: color ?? t.glass,
            borderRadius: BorderRadius.circular(radius),
            border: showBorder ? Border.all(color: t.borderStrong) : null,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Un carré arrondi portant une icône sur un fond doux. Sert d'ancrage visuel
/// aux lignes de liste, aux états vides et aux tuiles d'information.
class IconTile extends StatelessWidget {
  const IconTile({
    required this.icon,
    super.key,
    this.size = 44,
    this.color,
    this.background,
    this.gradient,
    this.borderColor,
  });

  final IconData icon;
  final double size;
  final Color? color;
  final Color? background;
  final Gradient? gradient;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final fg = color ?? t.brand;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: gradient == null ? (background ?? t.brandSoft) : null,
        gradient: gradient,
        shape: BoxShape.circle,
        border: gradient == null
            ? Border.all(color: borderColor ?? Colors.transparent)
            : null,
      ),
      child: Icon(icon, color: fg, size: size * 0.46),
    );
  }
}

/// La marque de l'application : un **disque** dégradé portant le glyphe.
///
/// Un cercle, pas un carré arrondi : un conteneur d'icône rond se lit comme
/// une marque, là où un rectangle arrondi se lit comme une tuile d'app. La
/// marque retient l'œil par sa couleur, jamais par un halo.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 56});

  final double size;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: t.brandGradient,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.local_activity_rounded,
        color: t.textOnBrand,
        size: size * 0.5,
      ),
    );
  }
}

/// Logo et nom de marque, pour les en-têtes et l'écran de démarrage.
class AppWordmark extends StatelessWidget {
  const AppWordmark({super.key, this.size = 40, this.showTagline = false});

  final double size;
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppLogo(size: size),
        const SizedBox(width: AppSpacing.md),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'EventHub',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontSize: size * 0.5,
                letterSpacing: -0.6,
              ),
            ),
            if (showTagline)
              Text('Vivez chaque instant', style: theme.textTheme.bodySmall),
          ],
        ),
      ],
    );
  }
}

/// Un filet qui respecte l'échelle des jetons et peut être mis en retrait.
class AppDivider extends StatelessWidget {
  const AppDivider({super.key, this.indent = 0, this.height = AppSpacing.lg});

  final double indent;
  final double height;

  @override
  Widget build(BuildContext context) => Divider(
    color: context.tokens.borderSubtle,
    indent: indent,
    endIndent: indent,
    height: height,
  );
}
