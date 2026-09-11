import 'dart:ui';

import 'package:eventhub/app/theme/theme.dart';
import 'package:flutter/material.dart';

/// How loudly a badge speaks.
enum BadgeStyle {
  /// Tinted background, coloured text. The default: readable without
  /// stealing attention from the content it annotates.
  soft,

  /// Fully saturated. Reserved for states the user must not miss
  /// ("Complet", "En direct").
  solid,

  /// Transparent with a coloured hairline. For badges laid over imagery.
  outline,
}

/// Compact status label.
///
/// Deliberately small and uppercase with generous tracking: a badge is a
/// *machine* label, not prose, and the typographic treatment signals that
/// at a glance.
class AppBadge extends StatelessWidget {
  const AppBadge({
    required this.label,
    super.key,
    this.tone = AppTone.brand,
    this.style = BadgeStyle.soft,
    this.icon,
    this.dense = false,
  });

  final String label;
  final AppTone tone;
  final BadgeStyle style;
  final IconData? icon;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final colors = context.tokens.resolve(tone);
    final (bg, fg, border) = switch (style) {
      BadgeStyle.soft => (colors.bg, colors.fg, null),
      BadgeStyle.solid => (colors.solid, colors.onSolid, null),
      BadgeStyle.outline => (Colors.transparent, colors.fg, colors.border),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? AppSpacing.sm : AppSpacing.md,
        vertical: dense ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.brPill,
        border: border == null ? null : Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? 10 : 12, color: fg),
            const SizedBox(width: 5),
          ],
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fg,
              fontSize: dense ? 9 : 10,
            ),
          ),
        ],
      ),
    );
  }
}

/// A pulsing dot + label, for "live" states that benefit from motion.
class LiveBadge extends StatefulWidget {
  const LiveBadge({
    required this.label,
    super.key,
    this.tone = AppTone.success,
  });

  final String label;
  final AppTone tone;

  @override
  State<LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<LiveBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tokens.resolve(widget.tone);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: colors.solid,
        borderRadius: AppRadius.brPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: Tween<double>(begin: 0.35, end: 1).animate(_controller),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: colors.onSolid,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            widget.label.toUpperCase(),
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: colors.onSolid),
          ),
        ],
      ),
    );
  }
}

/// Frosted two-line date chip laid over an event cover.
///
/// It is the calendar-page metaphor every ticketing app uses, because a
/// date is the first thing a user scans for on an event card.
class DateBadge extends StatelessWidget {
  const DateBadge({
    required this.month,
    required this.day,
    super.key,
    this.compact = false,
  });

  final String month;
  final String day;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? AppSpacing.sm : AppSpacing.md,
            vertical: compact ? 5 : AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                month.toUpperCase(),
                style: text.labelSmall?.copyWith(
                  color: AppPalette.iris700,
                  fontSize: compact ? 9 : 10,
                ),
              ),
              Text(
                day,
                style: text.titleLarge?.copyWith(
                  color: AppPalette.neutral900,
                  fontSize: compact ? 16 : 19,
                  height: 1.05,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Numeric counter chip — unread notifications, participants, filters
/// applied. Uses tabular figures so the width does not dance.
class CountBadge extends StatelessWidget {
  const CountBadge({
    required this.count,
    super.key,
    this.tone = AppTone.brand,
    this.max = 99,
  });

  final int count;
  final AppTone tone;
  final int max;

  @override
  Widget build(BuildContext context) {
    final colors = context.tokens.resolve(tone);
    return Container(
      constraints: const BoxConstraints(minWidth: 20),
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.solid,
        borderRadius: AppRadius.brPill,
      ),
      child: Text(
        count > max ? '$max+' : '$count',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colors.onSolid,
          letterSpacing: 0,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
