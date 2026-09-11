import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/config/app_config.dart';
import 'package:eventhub/core/extensions/context_x.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/auth/application/auth_providers.dart';
import 'package:eventhub/features/events/application/event_form_controller.dart';
import 'package:eventhub/features/events/application/event_providers.dart';
import 'package:eventhub/features/events/domain/entities/event.dart';
import 'package:eventhub/features/organizer/presentation/widgets/organizer_event_tile.dart';
import 'package:eventhub/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Organizer dashboard.
///
/// Opens on numbers, not on a list: three KPI tiles answer "comment vont
/// mes événements ?" before the organizer has to read a single title. The
/// list below is then split into upcoming and past, because the actions
/// available on a finished event are not the same.
class OrganizerDashboardScreen extends ConsumerStatefulWidget {
  const OrganizerDashboardScreen({super.key});

  @override
  ConsumerState<OrganizerDashboardScreen> createState() =>
      _OrganizerDashboardScreenState();
}

class _OrganizerDashboardScreenState
    extends ConsumerState<OrganizerDashboardScreen> {
  bool _showPast = false;

  Future<void> _delete(Event event) async {
    final confirmed = await showConfirmSheet(
      context,
      title: AppStrings.deleteEvent,
      message: AppStrings.deleteEventConfirm,
      confirmLabel: AppStrings.deletePermanently,
    );
    if (!confirmed || !mounted) return;

    final result = await ref
        .read(eventActionsControllerProvider.notifier)
        .delete(event.id);
    if (!mounted) return;
    switch (result) {
      case Ok():
        context.showSuccess(AppStrings.eventDeleted);
      case Err(:final failure):
        context.showFailure(failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();

    final events = ref.watch(organizerEventsProvider(user.id));
    final now = ref.watch(clockProvider)();

    return AppScaffold(
      constrainWidth: false,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(organizerEventsProvider(user.id)),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: ScreenHeader(
                  eyebrow: AppStrings.organizer,
                  title: AppStrings.myEvents,
                  subtitle: AppStrings.myEventsSubtitle,
                  trailing: GradientFab(
                    icon: Icons.add_rounded,
                    tooltip: AppStrings.createEvent,
                    onPressed: () => context.push(AppRoutes.organizerEventNew),
                  ),
                ),
              ),
              AsyncValueWidget(
                value: events,
                sliver: true,
                onRetry: () => ref.invalidate(organizerEventsProvider(user.id)),
                isEmpty: (list) => list.isEmpty,
                loading: SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.gutter,
                  ),
                  sliver: SliverList.separated(
                    itemCount: 2,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.lg),
                    itemBuilder: (_, __) =>
                        const Skeleton(height: 260, radius: AppRadius.xl),
                  ),
                ),
                empty: SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyStateView(
                    icon: Icons.add_business_rounded,
                    title: AppStrings.noOrganizerEventsTitle,
                    message: AppStrings.noOrganizerEvents,
                    action: AppButton.primary(
                      label: AppStrings.createFirstEvent,
                      icon: Icons.add_rounded,
                      expand: false,
                      onPressed: () =>
                          context.push(AppRoutes.organizerEventNew),
                    ),
                  ),
                ),
                data: (list) => _Dashboard(
                  events: list,
                  now: now,
                  showPast: _showPast,
                  onToggle: (v) => setState(() => _showPast = v),
                  onDelete: _delete,
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: AppSizes.navBarInset),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard({
    required this.events,
    required this.now,
    required this.showPast,
    required this.onToggle,
    required this.onDelete,
  });

  final List<Event> events;
  final DateTime now;
  final bool showPast;
  // ignore: avoid_positional_boolean_parameters
  final void Function(bool) onToggle;
  final void Function(Event) onDelete;

  @override
  Widget build(BuildContext context) {
    final upcoming = events.where((e) => !e.hasStarted(now)).toList();
    final past = events.where((e) => e.hasStarted(now)).toList();
    final visible = showPast ? past : upcoming;

    final booked = events.fold<int>(0, (sum, e) => sum + e.reservedCount);
    final capacity = events.fold<int>(0, (sum, e) => sum + e.capacity);
    final rate = capacity == 0 ? 0 : (booked / capacity * 100).round();

    return SliverList.list(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
          child: Row(
            children: [
              Expanded(
                child: StatTile(
                  value: '${upcoming.length}',
                  label: AppStrings.upcoming,
                  icon: Icons.event_note_rounded,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: StatTile(
                  value: '$booked',
                  label: AppStrings.totalParticipants,
                  icon: Icons.groups_2_rounded,
                  tone: AppTone.info,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: StatTile(
                  value: '$rate%',
                  label: AppStrings.fillRate,
                  icon: Icons.insights_rounded,
                  tone: rate >= 80 ? AppTone.success : AppTone.warning,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
          child: Row(
            children: [
              _Toggle(
                label: '${AppStrings.upcoming} (${upcoming.length})',
                selected: !showPast,
                onTap: () => onToggle(false),
              ),
              const SizedBox(width: AppSpacing.sm),
              _Toggle(
                label: '${AppStrings.pastEvents} (${past.length})',
                selected: showPast,
                onTap: () => onToggle(true),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (visible.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.giant),
            child: EmptyStateView(
              icon: showPast
                  ? Icons.history_rounded
                  : Icons.event_available_rounded,
              message: showPast
                  ? 'Aucun événement terminé pour le moment.'
                  : 'Aucun événement à venir. Créez-en un nouveau !',
            ),
          )
        else
          for (final event in visible) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.gutter,
              ),
              child: OrganizerEventTile(
                event: event,
                now: now,
                onParticipants: () => context.push(
                  AppRoutes.organizerEventParticipantsPath(event.id),
                ),
                onEdit: () =>
                    context.push(AppRoutes.organizerEventEditPath(event.id)),
                onDelete: () => onDelete(event),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
      ],
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Material(
      color: selected ? t.brand : t.surface,
      borderRadius: AppRadius.brPill,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.brPill,
            border: Border.all(color: selected ? t.brand : t.border),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: selected ? t.textOnBrand : t.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
