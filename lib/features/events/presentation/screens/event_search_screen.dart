import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/events/application/event_providers.dart';
import 'package:eventhub/features/events/domain/entities/event_category.dart';
import 'package:eventhub/features/events/presentation/widgets/event_card.dart';
import 'package:eventhub/features/events/presentation/widgets/event_filters.dart';
import 'package:eventhub/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Search & discovery.
///
/// Idle state is not an empty page: with no query and no filter the screen
/// becomes a **browse** surface (category grid with live counts). A search
/// screen that shows nothing until you type wastes the moment where the
/// user does not yet know what they want.
class EventSearchScreen extends ConsumerWidget {
  const EventSearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(filteredEventsProvider);
    final query = ref.watch(eventSearchQueryProvider);
    final filterCount = ref.watch(activeFilterCountProvider);
    final isIdle = query.isEmpty && filterCount == 0;
    final count = events.value?.length;

    return AppScaffold(
      constrainWidth: false,
      dense: true,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: ScreenHeader(title: AppStrings.search),
            ),
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                0,
                AppSpacing.gutter,
                AppSpacing.lg,
              ),
              sliver: SliverToBoxAdapter(
                child: EventSearchField(hint: AppStrings.searchHint),
              ),
            ),
            const SliverToBoxAdapter(child: CategoryFilterRail()),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                0,
                AppSpacing.gutter,
                AppSpacing.md,
              ),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    SectionLabel(
                      isIdle
                          ? AppStrings.browseByCategory
                          : count == null
                          ? AppStrings.results
                          : '${AppStrings.results} ($count)',
                    ),
                    const Spacer(),
                    const FilterButton(),
                  ],
                ),
              ),
            ),
            if (isIdle) const _CategoryBrowser() else const _Results(),
            const SliverToBoxAdapter(
              child: SizedBox(height: AppSizes.navBarInset),
            ),
          ],
        ),
      ),
    );
  }
}

class _Results extends ConsumerWidget {
  const _Results();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncValueWidget(
      value: ref.watch(filteredEventsProvider),
      sliver: true,
      onRetry: () => ref.invalidate(upcomingEventsProvider),
      isEmpty: (list) => list.isEmpty,
      loading: SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
        sliver: SliverList.separated(
          itemCount: 4,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (_, __) =>
              const Skeleton(height: 108, radius: AppRadius.lg),
        ),
      ),
      empty: SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyStateView(
          icon: Icons.search_off_rounded,
          title: AppStrings.noEventsTitle,
          message: AppStrings.noEventsMatch,
          action: AppButton.secondary(
            label: AppStrings.clearFilters,
            expand: false,
            size: AppButtonSize.medium,
            onPressed: ref.resetEventFilters,
          ),
        ),
      ),
      data: (list) => SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
        sliver: SliverList.separated(
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) {
            final event = list[index];
            return EventResultTile(
              event: event,
              onTap: () => context.push(AppRoutes.eventDetailPath(event.id)),
            );
          },
        ),
      ),
    );
  }
}

/// Category grid with a live count per category — the count is what turns
/// a decorative grid into a navigation aid ("Concert 12" tells you it is
/// worth tapping).
class _CategoryBrowser extends ConsumerWidget {
  const _CategoryBrowser();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(upcomingEventsProvider).value ?? const [];

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
      sliver: SliverGrid.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 1.55,
        ),
        itemCount: EventCategory.values.length,
        itemBuilder: (context, index) {
          final category = EventCategory.values[index];
          final count = all.where((e) => e.category == category).length;
          return _CategoryCard(category: category, count: count);
        },
      ),
    );
  }
}

class _CategoryCard extends ConsumerWidget {
  const _CategoryCard({required this.category, required this.count});

  final EventCategory category;
  final int count;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = category.color(context);
    final text = Theme.of(context).textTheme;

    return AppSurface(
      elevation: SurfaceElevation.flat,
      radius: AppRadius.lg,
      color: category.tint(context),
      borderColor: color.withValues(alpha: 0.22),
      onTap: () =>
          ref.read(eventCategoryFilterProvider.notifier).select(category),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(category.icon, size: 24, color: color),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(category.label, style: text.titleMedium),
              const SizedBox(height: 2),
              Text(
                count == 0
                    ? 'Aucun événement'
                    : '$count événement${count > 1 ? 's' : ''}',
                style: text.bodySmall?.copyWith(color: color),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
