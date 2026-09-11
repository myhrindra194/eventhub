import 'package:eventhub/app/theme/theme.dart';
import 'package:flutter/material.dart';

/// Capacity meter: a track, a fill and a plain-language caption.
///
/// The colour is *derived* from scarcity (`AppTokens.seatTone`) rather than
/// passed in, so "il reste 2 places" is amber everywhere in the app without
/// any screen having to remember the threshold. Scarcity signalling is the
/// single most effective element on an event card — it deserves a component,
/// not an inline `LinearProgressIndicator`.
class CapacityMeter extends StatelessWidget {
  const CapacityMeter({
    required this.available,
    required this.capacity,
    super.key,
    this.showCaption = true,
    this.onImage = false,
    this.height = 5,
    this.caption,
  });

  final int available;
  final int capacity;
  final bool showCaption;

  /// Set when the meter is laid over a photo: the track becomes translucent
  /// white and the caption switches to white.
  final bool onImage;
  final double height;
  final String? caption;

  double get _fill => capacity <= 0 ? 0 : (capacity - available) / capacity;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final tone = t.seatTone(available: available, capacity: capacity);
    final text = Theme.of(context).textTheme;

    final label =
        caption ??
        (available <= 0
            ? 'Complet'
            : available == 1
            ? 'Dernière place'
            : '$available places restantes');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(height),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: _fill.clamp(0.0, 1.0)),
            duration: AppMotion.long,
            curve: AppMotion.decelerate,
            builder: (context, value, _) => LinearProgressIndicator(
              value: value,
              minHeight: height,
              backgroundColor: onImage
                  ? Colors.white.withValues(alpha: 0.24)
                  : t.surfaceSunken,
              color: tone.solid,
            ),
          ),
        ),
        if (showCaption) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(
                available <= 0
                    ? Icons.block_rounded
                    : Icons.local_fire_department_rounded,
                size: 13,
                color: onImage ? Colors.white : tone.fg,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: text.labelSmall?.copyWith(
                  color: onImage ? Colors.white : tone.fg,
                  letterSpacing: 0.2,
                ),
              ),
              const Spacer(),
              Text(
                '${capacity - available}/$capacity',
                style: text.labelSmall?.copyWith(
                  color: onImage
                      ? Colors.white.withValues(alpha: 0.75)
                      : t.textTertiary,
                  letterSpacing: 0.2,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// A single KPI: value, label, optional trend/icon. Organizer dashboards
/// live or die on how quickly these can be scanned, so the value is set in
/// display type and everything else recedes.
class StatTile extends StatelessWidget {
  const StatTile({
    required this.value,
    required this.label,
    super.key,
    this.icon,
    this.tone = AppTone.brand,
    this.trailing,
  });

  final String value;
  final String label;
  final IconData? icon;
  final AppTone tone;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final colors = t.resolve(tone);
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null)
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: colors.bg,
                    borderRadius: AppRadius.brXs,
                  ),
                  child: Icon(icon, size: 16, color: colors.fg),
                ),
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            value,
            style: text.headlineMedium?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: text.bodySmall, maxLines: 1),
        ],
      ),
    );
  }
}

/// Concentric-ring hero used by success screens. The outer glow is a radial
/// gradient rather than a shadow so it blooms symmetrically.
class SuccessHero extends StatelessWidget {
  const SuccessHero({
    super.key,
    this.icon = Icons.check_rounded,
    this.tone = AppTone.success,
    this.size = 148,
  });

  final IconData icon;
  final AppTone tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.tokens.resolve(tone);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.7, end: 1),
      duration: AppMotion.long,
      curve: AppMotion.spring,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: SizedBox.square(
        dimension: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                colors.solid.withValues(alpha: 0.28),
                colors.solid.withValues(alpha: 0),
              ],
            ),
          ),
          child: Center(
            child: Container(
              width: size * 0.53,
              height: size * 0.53,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.solid,
                boxShadow: [
                  BoxShadow(
                    color: colors.solid.withValues(alpha: 0.45),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Icon(icon, color: colors.onSolid, size: size * 0.26),
            ),
          ),
        ),
      ),
    );
  }
}
