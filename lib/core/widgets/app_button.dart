import 'dart:ui';

import 'package:eventhub/app/theme/theme.dart';
import 'package:flutter/material.dart';

/// Visual weight of an action. Exactly one [AppButtonVariant.primary] per
/// screen region: if everything shouts, nothing is emphasised.
enum AppButtonVariant {
  /// The single most important action. Brand gradient + glow.
  primary,

  /// A real alternative to the primary action. Surface + hairline.
  secondary,

  /// Low-emphasis but still a button. Brand tint, no border.
  tonal,

  /// Text-only. For tertiary or repeated actions inside dense layouts.
  ghost,

  /// Destructive and irreversible.
  danger,
}

enum AppButtonSize { small, medium, large }

/// The one button of the design system.
///
/// Behaviour baked in, so no screen has to re-implement it:
///  * a press scales the button by 2 % — physical feedback that a colour
///    change alone does not give;
///  * [isLoading] swaps the label for a spinner **and** blocks the callback,
///    which removes the classic double-submit bug from every form;
///  * a disabled button keeps its footprint so the layout never jumps.
class AppButton extends StatefulWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.large,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.loadingLabel,
    this.expand = true,
    this.elevated = true,
  });

  const AppButton.primary({
    required this.label,
    required this.onPressed,
    super.key,
    this.size = AppButtonSize.large,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.loadingLabel,
    this.expand = true,
    this.elevated = true,
  }) : variant = AppButtonVariant.primary;

  const AppButton.secondary({
    required this.label,
    required this.onPressed,
    super.key,
    this.size = AppButtonSize.large,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.loadingLabel,
    this.expand = true,
    this.elevated = true,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.tonal({
    required this.label,
    required this.onPressed,
    super.key,
    this.size = AppButtonSize.medium,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.loadingLabel,
    this.expand = false,
    this.elevated = true,
  }) : variant = AppButtonVariant.tonal;

  const AppButton.ghost({
    required this.label,
    required this.onPressed,
    super.key,
    this.size = AppButtonSize.medium,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.loadingLabel,
    this.expand = false,
    this.elevated = true,
  }) : variant = AppButtonVariant.ghost;

  const AppButton.danger({
    required this.label,
    required this.onPressed,
    super.key,
    this.size = AppButtonSize.large,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.loadingLabel,
    this.expand = true,
    this.elevated = true,
  }) : variant = AppButtonVariant.danger;

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool isLoading;
  final String? loadingLabel;

  /// Whether the button fills the available width. `true` for full-width
  /// calls to action, `false` for inline actions inside a row.
  final bool expand;

  /// Coloured drop shadow under the filled variants. Set `false` for flat
  /// surfaces — the authentication screens run completely shadowless, where
  /// a glow would be the only piece of depth on an otherwise plain page and
  /// would read as decoration rather than hierarchy.
  final bool elevated;

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
        ] else if (widget.icon != null) ...[
          Icon(widget.icon, size: _iconSize, color: style.foreground),
          const SizedBox(width: AppSpacing.sm),
        ],
        Flexible(child: label),
        if (!widget.isLoading && widget.trailingIcon != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Icon(widget.trailingIcon, size: _iconSize, color: style.foreground),
        ],
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
              // 6 px, per the product's radius scale: a drawn edge, not a
              // rounded rectangle pretending to be a pill.
              borderRadius: AppRadius.brButton,
              border: style.border == null
                  ? null
                  : Border.all(color: style.border!),
              boxShadow: widget.elevated ? style.shadow : null,
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
        shadow: [
          BoxShadow(
            color: t.brand.withValues(alpha: 0.34),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      AppButtonVariant.secondary => _ButtonStyle(
        background: t.surface,
        foreground: t.textPrimary,
        border: t.borderStrong,
        shadow: t.shadows.xs,
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
        shadow: [
          BoxShadow(
            color: t.danger.solid.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
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
    this.shadow,
  });

  final Color foreground;
  final Color? background;
  final Gradient? gradient;
  final Color? border;
  final List<BoxShadow>? shadow;
}

/// Square icon button sitting on a surface. Used for row-level actions
/// (edit, delete) where a labelled button would overwhelm the layout.
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

/// Circular frosted button floating over imagery (back, share, favourite).
/// The blur guarantees legibility whatever the photo underneath is.
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

/// Round gradient action button — the organizer's "create" affordance.
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
    final button = DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: t.brand.withValues(alpha: 0.38),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
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

/// Circular back affordance.
///
/// A solid accent disc with a white glyph, centred. It is deliberately the
/// **warm** colour rather than the brand indigo: "revenir" is the one action
/// on a form screen that is not the primary path, and giving it its own hue
/// keeps it findable without competing with the call to action underneath.
///
/// Circular here, 6 px everywhere else: a back control is a single glyph, and
/// a disc reads as a target the thumb can hit without aiming.
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
