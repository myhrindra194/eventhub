import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/utils/date_formats.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/events/domain/entities/event.dart';
import 'package:flutter/material.dart';

/// Organizer's view of one of their events.
///
/// Le participant voit une invitation ; l'organisateur, lui, a besoin d'un
/// tableau de bord. Même photo, hiérarchie de l'information différente : le
/// badge de cycle de vie d'abord (en ligne / complet / terminé), puis les
/// deux chiffres qui décident de la suite — remplissage, date — puis les
/// actions.
///
/// Un événement co-organisé (F-16) porte la mention « Co-organisé » et aucune
/// action de suppression : seul le propriétaire peut supprimer.
class OrganizerEventTile extends StatelessWidget {
  const OrganizerEventTile({
    required this.event,
    required this.now,
    required this.onParticipants,
    required this.onEdit,
    required this.onTeam,
    super.key,
    this.onDelete,
    this.coOrganized = false,
  });

  final Event event;
  final DateTime now;
  final VoidCallback onParticipants;
  final VoidCallback onEdit;
  final VoidCallback onTeam;

  /// `null` masque l'action — c'est le cas des événements co-organisés.
  final VoidCallback? onDelete;
  final bool coOrganized;

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
                  child: Row(
                    children: [
                      badge,
                      if (coOrganized) ...[
                        const SizedBox(width: AppSpacing.sm),
                        const AppBadge(
                          label: AppStrings.coOrganizedBadge,
                          tone: AppTone.info,
                          style: BadgeStyle.solid,
                        ),
                      ],
                    ],
                  ),
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
                        size: AppButtonSize.small,
                        expand: true,
                        onPressed: onParticipants,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    IconActionButton(
                      icon: Icons.diversity_3_rounded,
                      tooltip: AppStrings.teamTitle,
                      onPressed: onTeam,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    IconActionButton(
                      icon: Icons.edit_outlined,
                      tooltip: AppStrings.editEvent,
                      onPressed: onEdit,
                    ),
                    if (onDelete != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      IconActionButton(
                        icon: Icons.delete_outline_rounded,
                        tooltip: AppStrings.delete,
                        color: t.danger.fg,
                        background: t.danger.bg,
                        onPressed: onDelete,
                      ),
                    ],
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
