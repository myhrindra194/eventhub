import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/extensions/context_x.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/utils/date_formats.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/events/application/event_providers.dart';
import 'package:eventhub/features/reservations/application/reservation_providers.dart';
import 'package:eventhub/features/reservations/domain/entities/reservation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Guest list for one event.
///
/// The search box is not a nice-to-have: on the door, an organizer is
/// looking for *one* name in a list while someone waits in front of them.
/// Filtering happens on name and email, both of which a participant can
/// quote from memory.
class EventParticipantsScreen extends ConsumerStatefulWidget {
  const EventParticipantsScreen({required this.eventId, super.key});

  final String eventId;

  @override
  ConsumerState<EventParticipantsScreen> createState() =>
      _EventParticipantsScreenState();
}

class _EventParticipantsScreenState
    extends ConsumerState<EventParticipantsScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final event = ref.watch(eventByIdProvider(widget.eventId)).value;
    final participants = ref.watch(eventParticipantsProvider(widget.eventId));

    return AppScaffold(
      dense: true,
      appBar: AppBar(
        title: const Text(AppStrings.participants),
        bottom: event == null
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(24),
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: AppSpacing.gutter,
                    bottom: AppSpacing.md,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      event.title,
                      style: context.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
      ),
      body: Column(
        children: [
          if (event != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.md,
                AppSpacing.gutter,
                0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: StatTile(
                      value: '${event.reservedCount}',
                      label: AppStrings.booked,
                      icon: Icons.how_to_reg_rounded,
                      tone: AppTone.success,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: StatTile(
                      value: '${event.availablePlaces}',
                      label: AppStrings.remaining,
                      icon: Icons.event_seat_rounded,
                      tone: event.isFull ? AppTone.danger : AppTone.brand,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: StatTile(
                      value: '${(event.fillRate * 100).round()}%',
                      label: AppStrings.fillRate,
                      icon: Icons.insights_rounded,
                      tone: AppTone.info,
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.gutter),
            child: AppSearchField(
              hint: AppStrings.searchParticipants,
              controller: _controller,
              value: _query,
              onChanged: (v) => setState(() => _query = v),
              onClear: () {
                _controller.clear();
                setState(() => _query = '');
              },
            ),
          ),
          Expanded(
            child: AsyncValueWidget(
              value: participants,
              onRetry: () =>
                  ref.invalidate(eventParticipantsProvider(widget.eventId)),
              isEmpty: (list) => list.isEmpty,
              empty: const EmptyStateView(
                icon: Icons.person_search_rounded,
                message: AppStrings.noParticipants,
              ),
              data: (list) {
                final query = _query.trim().toLowerCase();
                final filtered = query.isEmpty
                    ? list
                    : list
                          .where(
                            (r) =>
                                r.userName.toLowerCase().contains(query) ||
                                r.userEmail.toLowerCase().contains(query),
                          )
                          .toList();

                if (filtered.isEmpty) {
                  return const EmptyStateView(
                    icon: Icons.person_search_rounded,
                    message: 'Aucun participant ne correspond à ce filtre.',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.gutter,
                    0,
                    AppSpacing.gutter,
                    AppSpacing.huge,
                  ),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) => _ParticipantRow(
                    reservation: filtered[index],
                    index: index,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ParticipantRow extends StatelessWidget {
  const _ParticipantRow({required this.reservation, required this.index});

  final Reservation reservation;
  final int index;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return AppSurface(
      padding: const EdgeInsets.all(AppSpacing.md),
      elevation: SurfaceElevation.flat,
      radius: AppRadius.md,
      child: Row(
        children: [
          SizedBox(
            width: 26,
            child: Text(
              '${index + 1}',
              style: text.labelSmall?.copyWith(letterSpacing: 0),
              textAlign: TextAlign.center,
            ),
          ),
          AppAvatar(name: reservation.userName, size: 42),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reservation.userName,
                  style: text.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  reservation.userEmail,
                  style: text.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Icon(Icons.check_circle_rounded, size: 16, color: t.success.fg),
              const SizedBox(height: AppSpacing.xs),
              Text(
                AppDateFormats.shortDate(reservation.reservedAt),
                style: text.labelSmall?.copyWith(letterSpacing: 0),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
