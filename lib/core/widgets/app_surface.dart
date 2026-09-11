import 'dart:ui';

import 'package:eventhub/app/theme/theme.dart';
import 'package:flutter/material.dart';

/// Elevation levels available to a surface. They map to shadow recipes, not
/// to Material's numeric elevation, so a card looks lifted on a dark ground
/// instead of merely tinted.
enum SurfaceElevation { flat, low, medium, high }

/// The single container primitive of the design system.
///
/// Everything that is "a box with content on it" — cards, tiles, panels,
/// list rows — is an [AppSurface]. Consistency of radius, border and shadow
/// across the app comes for free, and a design change is one edit here.
class AppSurface extends StatelessWidget {
  const AppSurface({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.margin,
    this.radius = AppRadius.xl,
    this.elevation = SurfaceElevation.low,
    this.color,
    this.borderColor,
    this.gradient,
    this.onTap,
    this.onLongPress,
    this.clip = true,
    this.width,
    this.height,
  });

  /// Convenience: a surface with no padding, for image-led cards that
  /// manage their own insets.
  const AppSurface.bare({
    required this.child,
    super.key,
    this.margin,
    this.radius = AppRadius.xl,
    this.elevation = SurfaceElevation.low,
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
  final SurfaceElevation elevation;
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
    final shadows = switch (elevation) {
      SurfaceElevation.flat => const <BoxShadow>[],
      SurfaceElevation.low => t.shadows.sm,
      SurfaceElevation.medium => t.shadows.md,
      SurfaceElevation.high => t.shadows.lg,
    };

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
        boxShadow: shadows,
      ),
      child: content,
    );
  }
}

/// Translucent, blurred panel. Reserved for elements that must let the
/// content underneath show through — sheets, floating bars, overlays on
/// photography. Blur is expensive: do not use it for ordinary cards.
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

/// A rounded square holding an icon on a soft ground. Used as the visual
/// anchor of list rows, empty states and info tiles.
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

/// The app mark: a gradient **disc** carrying the glyph.
///
/// A circle, not a rounded square: an icon container that is round reads as
/// a mark, while a rounded rectangle reads as an app tile. [glow] is off by
/// default — the mark should hold the eye by its colour, not by a halo.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 56, this.glow = false});

  final double size;
  final bool glow;

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
        boxShadow: glow
            ? [
                BoxShadow(
                  color: t.brand.withValues(alpha: 0.4),
                  blurRadius: size * 0.5,
                  offset: Offset(0, size * 0.18),
                ),
              ]
            : null,
      ),
      child: Icon(
        Icons.local_activity_rounded,
        color: t.textOnBrand,
        size: size * 0.5,
      ),
    );
  }
}

/// Logo + wordmark, for headers and splash screens.
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

/// A hairline that respects the token scale and can be inset.
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
