import 'dart:ui';

import 'package:eventhub/app/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Fond d’écran d’ambiance.
///
/// Deux halos radiaux très doux posés sur la couleur du canvas. Cela donne
/// de la profondeur à un fond plat sans embarquer d’image, se lit
/// correctement dans les deux thèmes (les couleurs des halos sont des
/// tokens) et — surtout — reste bon marché : deux dégradés, aucun flou,
/// aucun shader.
///
/// [dense] divise par deux l’opacité des halos pour les écrans denses en
/// contenu (listes, formulaires) où le fond doit s’effacer complètement.
class AuroraBackground extends StatelessWidget {
  const AuroraBackground({
    required this.child,
    super.key,
    this.dense = false,
    this.showBlooms = true,
  });

  final Widget child;
  final bool dense;
  final bool showBlooms;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final opacity = dense ? 0.45 : 1.0;

    return DecoratedBox(
      decoration: BoxDecoration(color: t.canvas),
      child: Stack(
        children: [
          if (showBlooms) ...[
            Positioned(
              top: -160,
              left: -110,
              child: _Bloom(
                color: t.bloomPrimary.withValues(
                  alpha: t.bloomPrimary.a * opacity,
                ),
                size: 420,
              ),
            ),
            Positioned(
              top: 90,
              right: -180,
              child: _Bloom(
                color: t.bloomSecondary.withValues(
                  alpha: t.bloomSecondary.a * opacity,
                ),
                size: 400,
              ),
            ),
          ],
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class _Bloom extends StatelessWidget {
  const _Bloom({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.square(
        dimension: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color, color.withValues(alpha: 0)],
            ),
          ),
        ),
      ),
    );
  }
}

/// L’habillage d’écran standard.
///
/// Enveloppe [AuroraBackground], applique le style d’overlay système du
/// thème courant et contraint le contenu à [AppSizes.maxContentWidth] sur
/// les fenêtres larges — pour qu’une tablette n’hérite pas d’un paragraphe
/// de 1000 px de large.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    required this.body,
    super.key,
    this.appBar,
    this.bottomBar,
    this.floatingActionButton,
    this.dense = false,
    this.showBlooms = true,
    this.extendBody = true,
    this.constrainWidth = true,
    this.resizeToAvoidBottomInset,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomBar;
  final Widget? floatingActionButton;
  final bool dense;
  final bool showBlooms;
  final bool extendBody;
  final bool constrainWidth;
  final bool? resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    final content = constrainWidth
        ? Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSizes.maxContentWidth,
              ),
              child: body,
            ),
          )
        : body;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.overlayStyle(Theme.of(context).brightness),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: extendBody,
        extendBodyBehindAppBar: appBar == null,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        appBar: appBar,
        bottomNavigationBar: bottomBar,
        floatingActionButton: floatingActionButton,
        body: AuroraBackground(
          dense: dense,
          showBlooms: showBlooms,
          child: content,
        ),
      ),
    );
  }
}

/// Une barre dépolie posée au-dessus du contenu qui défile (barres d’action
/// collantes, barres de navigation). Retombe sur un aplat opaque là où le
/// flou coûte cher.
class FrostedBar extends StatelessWidget {
  const FrostedBar({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.gutter,
      vertical: AppSpacing.lg,
    ),
    this.borderRadius,
    this.showTopBorder = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;
  final bool showTopBorder;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: t.glass,
            borderRadius: borderRadius,
            border: showTopBorder
                ? Border(top: BorderSide(color: t.borderSubtle))
                : null,
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
