import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/utils/date_formats.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/events/domain/entities/event.dart';
import 'package:flutter/material.dart';

/// Organizer's view of one of their events.
///
/// The participant sees an invitation; the organizer needs an instrument
/// panel. Same photo, different information hierarchy: lifecycle badge
/// first (en ligne / complet / terminé), then the two numbers that decide
/// what to do next (remplissage, date), then the actions.
class OrganizerEventTile extends StatelessWidget {
  const OrganizerEventTile({
    required this.event,
    required this.now,
    required this.onParticipants,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final Event event;
  final DateTime now;
  final VoidCallback onParticipants;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final isPast = event.hasStarted(now);

    final badge = isPast
        ? const AppBadge(label: AppStrings.past, tone: AppTone.neutral)
        : event.isFull
        ? const AppBadge(
            label: AppStrings.soldOut,
            tone: AppTone.danger,
            style: BadgeStyle.solid,
          )
        : const LiveBadge(label: AppStrings.live);

    return AppSurface.bare(
      elevation: SurfaceElevation.medium,
      onTap: onParticipants,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 7.5,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Opacity(
                  opacity: isPast ? 0.55 : 1,
                  child: EventImage(imageUrl: event.imageUrl, seed: event.id),
                ),
                DecoratedBox(decoration: BoxDecoration(gradient: t.heroScrim)),
                Positioned(
                  top: AppSpacing.md,
                  left: AppSpacing.md,
                  child: badge,
                ),
                Positioned(
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  bottom: AppSpacing.md,
                  child: Text(
                    event.title,
                    style: text.headlineSmall?.copyWith(color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_month_rounded,
                      size: 14,
                      color: t.textTertiary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      AppDateFormats.dayMonthTime(event.startsAt),
                      style: text.bodySmall,
                    ),
                    const Spacer(),
                    Icon(Icons.place_outlined, size: 14, color: t.textTertiary),
                    const SizedBox(width: AppSpacing.xs),
                    Flexible(
                      child: Text(
                        event.location,
                        style: text.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                CapacityMeter(
                  available: event.availablePlaces,
                  capacity: event.capacity,
                  height: 6,
                  caption:
                      '${event.reservedCount} participant'
                      '${event.reservedCount > 1 ? 's' : ''}',
                ),
                const AppDivider(height: AppSpacing.xl),
                Row(
                  children: [
                    Expanded(
                      child: AppButton.tonal(
                        label: AppStrings.participants,
                        icon: Icons.groups_2_rounded,
                        size: AppButtonSize.small,
                        expand: true,
                        onPressed: onParticipants,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    IconActionButton(
                      icon: Icons.edit_outlined,
                      tooltip: AppStrings.editEvent,
                      onPressed: onEdit,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    IconActionButton(
                      icon: Icons.delete_outline_rounded,
                      tooltip: AppStrings.delete,
                      color: t.danger.fg,
                      background: t.danger.bg,
                      onPressed: onDelete,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
