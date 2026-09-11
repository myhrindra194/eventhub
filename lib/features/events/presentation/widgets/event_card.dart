import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/utils/date_formats.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/events/domain/entities/event.dart';
import 'package:eventhub/features/events/domain/entities/event_category.dart';
import 'package:flutter/material.dart';

/// Visual identity of a category.
///
/// Each category owns a hue and a glyph, declared once and reused by the
/// filter rail, the cards, the detail header and the organizer list. Two
/// variants per hue keep contrast comparable in both themes — a colour that
/// pops on white washes out on near-black.
extension EventCategoryStyle on EventCategory {
  IconData get icon => switch (this) {
    EventCategory.concert => Icons.graphic_eq_rounded,
    EventCategory.conference => Icons.record_voice_over_rounded,
    EventCategory.meetup => Icons.groups_2_rounded,
    EventCategory.workshop => Icons.construction_rounded,
    EventCategory.sport => Icons.directions_run_rounded,
    EventCategory.culture => Icons.museum_rounded,
    EventCategory.other => Icons.auto_awesome_rounded,
  };

  (Color light, Color dark) get _hues => switch (this) {
    EventCategory.concert => (AppPalette.fuchsia500, AppPalette.fuchsia400),
    EventCategory.conference => (AppPalette.iris600, AppPalette.iris400),
    EventCategory.meetup => (AppPalette.sky600, AppPalette.sky400),
    EventCategory.workshop => (AppPalette.amber600, AppPalette.amber400),
    EventCategory.sport => (AppPalette.mint600, AppPalette.mint400),
    EventCategory.culture => (AppPalette.violet500, AppPalette.violet400),
    EventCategory.other => (AppPalette.teal500, AppPalette.teal400),
  };

  Color color(BuildContext context) {
    final (light, dark) = _hues;
    return context.tokens.isDark ? dark : light;
  }

  /// Low-alpha version for chip and tile backgrounds.
  Color tint(BuildContext context) =>
      color(context).withValues(alpha: context.tokens.isDark ? 0.18 : 0.12);
}

/// Small category chip used over imagery and inside rows.
class CategoryChip extends StatelessWidget {
  const CategoryChip({
    required this.category,
    super.key,
    this.solid = true,
    this.dense = false,
  });

  final EventCategory category;
  final bool solid;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final color = category.color(context);
    final fg = solid ? Colors.white : color;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? AppSpacing.sm : AppSpacing.md,
        vertical: dense ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: solid ? color : category.tint(context),
        borderRadius: AppRadius.brPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(category.icon, size: dense ? 11 : 13, color: fg),
          const SizedBox(width: 5),
          Text(
            category.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fg,
              fontSize: dense ? 9.5 : 10.5,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// **Hero card** — the main unit of the feed.
///
/// Full-bleed artwork with the metadata laid over a scrim, in the order the
/// eye needs it: date badge (when), category (what kind), title (what),
/// place and time (where), scarcity meter (should I act now). Everything a
/// user needs to decide is on the card, so the detail page is a
/// confirmation step rather than a mandatory detour.
class EventCard extends StatelessWidget {
  const EventCard({
    required this.event,
    required this.onTap,
    super.key,
    this.aspectRatio = 4 / 3.15,
    this.showMeter = true,
  });

  final Event event;
  final VoidCallback onTap;
  final double aspectRatio;
  final bool showMeter;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return AppSurface.bare(
      elevation: SurfaceElevation.medium,
      borderColor: t.borderSubtle,
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: 'event-image-${event.id}',
              child: EventImage(imageUrl: event.imageUrl, seed: event.id),
            ),
            DecoratedBox(decoration: BoxDecoration(gradient: t.heroScrim)),
            Positioned(
              top: AppSpacing.md,
              left: AppSpacing.md,
              child: DateBadge(
                month: AppDateFormats.monthAbbr(event.startsAt),
                day: '${event.startsAt.day}',
              ),
            ),
            Positioned(
              top: AppSpacing.md,
              right: AppSpacing.md,
              child: event.isFull
                  ? const AppBadge(
                      label: AppStrings.soldOut,
                      tone: AppTone.danger,
                      style: BadgeStyle.solid,
                    )
                  : CategoryChip(category: event.category),
            ),
            Positioned(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: AppSpacing.lg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: text.headlineSmall?.copyWith(
                      color: Colors.white,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _MetaLine(event: event),
                  if (showMeter) ...[
                    const SizedBox(height: AppSpacing.md),
                    CapacityMeter(
                      available: event.availablePlaces,
                      capacity: event.capacity,
                      onImage: true,
                      height: 4,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Colors.white.withValues(alpha: 0.85),
    );
    return Row(
      children: [
        const Icon(Icons.place_rounded, size: 13, color: Colors.white70),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            event.location,
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        const Icon(Icons.schedule_rounded, size: 13, color: Colors.white70),
        const SizedBox(width: AppSpacing.xs),
        Text(AppDateFormats.time(event.startsAt), style: style),
      ],
    );
  }
}

/// **Rail card** — a narrow portrait card for horizontal sections
/// ("Cette semaine", "Ça se remplit vite"). Same language as the hero card,
/// a third of the surface.
class EventRailCard extends StatelessWidget {
  const EventRailCard({
    required this.event,
    required this.onTap,
    super.key,
    this.width = 208,
  });

  final Event event;
  final VoidCallback onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return SizedBox(
      width: width,
      child: AppSurface.bare(
        radius: AppRadius.lg,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 116,
                  width: double.infinity,
                  child: EventImage(imageUrl: event.imageUrl, seed: event.id),
                ),
                Positioned(
                  top: AppSpacing.sm,
                  left: AppSpacing.sm,
                  child: DateBadge(
                    month: AppDateFormats.monthAbbr(event.startsAt),
                    day: '${event.startsAt.day}',
                    compact: true,
                  ),
                ),
                if (event.isFull)
                  const Positioned(
                    top: AppSpacing.sm,
                    right: AppSpacing.sm,
                    child: AppBadge(
                      label: AppStrings.soldOut,
                      tone: AppTone.danger,
                      style: BadgeStyle.solid,
                      dense: true,
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        event.category.icon,
                        size: 11,
                        color: event.category.color(context),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        event.category.label.toUpperCase(),
                        style: text.labelSmall?.copyWith(
                          color: event.category.color(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    height: 38,
                    child: Text(
                      event.title,
                      style: text.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Icon(
                        Icons.place_outlined,
                        size: 12,
                        color: t.textTertiary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          event.location,
                          style: text.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// **Result row** — dense horizontal layout for search results and any
/// list where scanning many items beats admiring a few.
class EventResultTile extends StatelessWidget {
  const EventResultTile({required this.event, required this.onTap, super.key});

  final Event event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return AppSurface(
      padding: const EdgeInsets.all(AppSpacing.md),
      radius: AppRadius.lg,
      elevation: SurfaceElevation.flat,
      onTap: onTap,
      child: Row(
        children: [
          SizedBox(
            width: 84,
            height: 84,
            child: EventImage(
              imageUrl: event.imageUrl,
              seed: event.id,
              borderRadius: AppRadius.brSm,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      event.category.icon,
                      size: 11,
                      color: event.category.color(context),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      event.category.label.toUpperCase(),
                      style: text.labelSmall?.copyWith(
                        color: event.category.color(context),
                      ),
                    ),
                    if (event.isFull) ...[
                      const SizedBox(width: AppSpacing.sm),
                      const AppBadge(
                        label: AppStrings.soldOut,
                        tone: AppTone.danger,
                        dense: true,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  event.title,
                  style: text.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 11,
                      color: t.textTertiary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        '${AppDateFormats.dayMonthTime(event.startsAt)} · '
                        '${event.location}',
                        style: text.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: t.textTertiary),
        ],
      ),
    );
  }
}

/// Placeholder matching [EventCard]'s footprint, so the feed does not
/// reflow when data arrives.
class EventCardSkeleton extends StatelessWidget {
  const EventCardSkeleton({super.key, this.aspectRatio = 4 / 3.15});

  final double aspectRatio;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: aspectRatio,
    child: const Skeleton(height: double.infinity, radius: AppRadius.xl),
  );
}
