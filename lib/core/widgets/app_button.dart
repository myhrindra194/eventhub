import 'dart:ui';

import 'package:eventhub/app/theme/theme.dart';
import 'package:flutter/material.dart';

/// Le poids visuel d'une action. Exactement un [AppButtonVariant.primary] par
/// région d'écran : si tout crie, plus rien ne ressort.
enum AppButtonVariant {
  /// L'action la plus importante, et la seule à ce rang. Dégradé de marque.
  primary,

  /// Une véritable alternative à l'action principale. Surface et filet.
  secondary,

  /// Peu appuyé, mais toujours un bouton. Teinte de marque, sans bordure.
  tonal,

  /// Texte seul. Pour les actions tertiaires ou répétées dans une mise en
  /// page dense.
  ghost,

  /// Destructeur et irréversible.
  danger,
}

enum AppButtonSize { small, medium, large }

/// L'unique bouton du design system.
///
/// Son comportement est intégré, pour qu'aucun écran n'ait à le réécrire :
///  * l'appui réduit le bouton de 2 % — un retour physique qu'un simple
///    changement de couleur ne donne pas ;
///  * [isLoading] remplace le libellé par un indicateur **et** bloque le
///    rappel, ce qui supprime de tous les formulaires le classique double
///    envoi ;
///  * un bouton désactivé conserve son encombrement, si bien que la mise en
///    page ne saute jamais.
class AppButton extends StatefulWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.large,
    this.isLoading = false,
    this.loadingLabel,
    this.expand = true,
  });

  const AppButton.primary({
    required this.label,
    required this.onPressed,
    super.key,
    this.size = AppButtonSize.large,
    this.isLoading = false,
    this.loadingLabel,
    this.expand = true,
  }) : variant = AppButtonVariant.primary;

  const AppButton.secondary({
    required this.label,
    required this.onPressed,
    super.key,
    this.size = AppButtonSize.large,
    this.isLoading = false,
    this.loadingLabel,
    this.expand = true,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.tonal({
    required this.label,
    required this.onPressed,
    super.key,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.loadingLabel,
    this.expand = false,
  }) : variant = AppButtonVariant.tonal;

  const AppButton.ghost({
    required this.label,
    required this.onPressed,
    super.key,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.loadingLabel,
    this.expand = false,
  }) : variant = AppButtonVariant.ghost;

  const AppButton.danger({
    required this.label,
    required this.onPressed,
    super.key,
    this.size = AppButtonSize.large,
    this.isLoading = false,
    this.loadingLabel,
    this.expand = true,
  }) : variant = AppButtonVariant.danger;

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool isLoading;
  final String? loadingLabel;

  /// Si le bouton occupe toute la largeur disponible : `true` pour un appel
  /// à l'action pleine largeur, `false` pour une action en ligne dans une
  /// rangée.
  final bool expand;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null && !widget.isLoading;

  double get _height => switch (widget.size) {
    AppButtonSize.small => AppSizes.buttonSm,
    AppButtonSize.medium => AppSizes.buttonMd,
    AppButtonSize.large => AppSizes.buttonLg,
  };

  double get _fontSize => switch (widget.size) {
    AppButtonSize.small => 13,
    AppButtonSize.medium => 14,
    AppButtonSize.large => 15,
  };

  double get _iconSize => switch (widget.size) {
    AppButtonSize.small => 16,
    AppButtonSize.medium => 18,
    AppButtonSize.large => 19,
  };

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final style = _resolve(t);

    final label = Text(
      widget.isLoading ? (widget.loadingLabel ?? widget.label) : widget.label,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontSize: _fontSize,
        fontWeight: FontWeight.w700,
        color: style.foreground,
        letterSpacing: 0,
      ),
      overflow: TextOverflow.ellipsis,
    );

    final row = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading) ...[
          SizedBox.square(
            dimension: _iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: style.foreground,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        Flexible(child: label),
      ],
    );

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.label,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration: AppMotion.xshort,
        curve: AppMotion.standard,
        child: GestureDetector(
          onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          onTap: _enabled ? widget.onPressed : null,
          child: AnimatedContainer(
            duration: AppMotion.short,
            curve: AppMotion.standard,
            height: _height,
            width: widget.expand ? double.infinity : null,
            padding: EdgeInsets.symmetric(
              horizontal: widget.expand ? AppSpacing.lg : AppSpacing.xl,
            ),
            decoration: BoxDecoration(
              color: style.background,
              gradient: style.gradient,
              // 6 px, selon l'échelle de rayons du produit : une arête
              // dessinée, et non un rectangle arrondi qui se prendrait pour
              // une pastille.
              borderRadius: AppRadius.brButton,
              border: style.border == null
                  ? null
                  : Border.all(color: style.border!),
            ),
            child: row,
          ),
        ),
      ),
    );
  }

  _ButtonStyle _resolve(AppTokens t) {
    if (!_enabled && !widget.isLoading) {
      return _ButtonStyle(
        background: t.surfaceSunken,
        foreground: t.textTertiary,
        border: t.borderSubtle,
      );
    }

    return switch (widget.variant) {
      AppButtonVariant.primary => _ButtonStyle(
        gradient: t.brandGradient,
        foreground: t.textOnBrand,
      ),
      AppButtonVariant.secondary => _ButtonStyle(
        background: t.surface,
        foreground: t.textPrimary,
        border: t.borderStrong,
      ),
      AppButtonVariant.tonal => _ButtonStyle(
        background: t.brandSoft,
        foreground: t.brand,
      ),
      AppButtonVariant.ghost => _ButtonStyle(
        background: Colors.transparent,
        foreground: t.textSecondary,
      ),
      AppButtonVariant.danger => _ButtonStyle(
        background: t.danger.solid,
        foreground: t.danger.onSolid,
      ),
    };
  }
}

class _ButtonStyle {
  const _ButtonStyle({
    required this.foreground,
    this.background,
    this.gradient,
    this.border,
  });

  final Color foreground;
  final Color? background;
  final Gradient? gradient;
  final Color? border;
}

/// Bouton d'icône carré posé sur une surface. Pour les actions au niveau
/// d'une ligne — modifier, supprimer — où un bouton à libellé écraserait la
/// mise en page.
class IconActionButton extends StatelessWidget {
  const IconActionButton({
    required this.icon,
    required this.onPressed,
    super.key,
    this.tooltip,
    this.color,
    this.background,
    this.size = 40,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? color;
  final Color? background;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final button = Material(
      color: background ?? t.surfaceSunken,
      borderRadius: AppRadius.brButton,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox.square(
          dimension: size,
          child: Icon(icon, size: size * 0.45, color: color ?? t.textSecondary),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

/// Bouton circulaire flouté, flottant au-dessus d'une image — retour,
/// partage, favori. Le flou garantit la lisibilité quelle que soit la photo
/// qui se trouve dessous.
class OverlayIconButton extends StatelessWidget {
  const OverlayIconButton({
    required this.icon,
    required this.onPressed,
    super.key,
    this.tooltip,
    this.foreground = Colors.white,
    this.size = 42,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final Color foreground;
  final double size;

  @override
  Widget build(BuildContext context) {
    final button = ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Material(
          color: Colors.black.withValues(alpha: 0.32),
          shape: const CircleBorder(side: BorderSide(color: Color(0x33FFFFFF))),
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: SizedBox.square(
              dimension: size,
              child: Icon(icon, size: size * 0.48, color: foreground),
            ),
          ),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

/// Bouton d'action rond et dégradé — le geste « créer » de l'organisateur.
class GradientFab extends StatelessWidget {
  const GradientFab({
    required this.icon,
    required this.onPressed,
    super.key,
    this.size = 52,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final double size;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    // Pas de halo sous le bouton : le dégradé de marque sur le fond calme de
    // l'écran suffit à en faire l'élément le plus saillant de la page.
    final button = DecoratedBox(
      decoration: const BoxDecoration(shape: BoxShape.circle),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: t.brandGradient,
          ),
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: SizedBox.square(
              dimension: size,
              child: Icon(icon, color: t.textOnBrand, size: size * 0.48),
            ),
          ),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

/// Le retour, en disque.
///
/// Un disque plein de la couleur d'accent, glyphe blanc centré. C'est
/// délibérément la couleur **chaude** et non l'indigo de marque : « revenir »
/// est la seule action d'un écran de formulaire qui ne soit pas le chemin
/// principal, et lui donner sa propre teinte la rend repérable sans qu'elle
/// concurrence l'appel à l'action situé dessous.
///
/// Rond ici, 6 px partout ailleurs : un retour n'est qu'un glyphe, et un
/// disque se lit comme une cible que le pouce atteint sans viser.
class CircleBackButton extends StatelessWidget {
  const CircleBackButton({
    required this.onPressed,
    super.key,
    this.icon = Icons.arrow_back_rounded,
    this.size = 44,
    this.tooltip = 'Retour',
  });

  final VoidCallback onPressed;
  final IconData icon;
  final double size;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    final button = Material(
      color: t.accent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox.square(
          dimension: size,
          child: Center(
            child: Icon(icon, size: size * 0.48, color: Colors.white),
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      label: tooltip,
      child: tooltip == null
          ? button
          : Tooltip(message: tooltip!, child: button),
    );
  }
}
