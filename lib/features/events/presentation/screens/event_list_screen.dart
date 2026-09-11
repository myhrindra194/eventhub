import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/config/app_config.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/auth/application/auth_providers.dart';
import 'package:eventhub/features/events/application/event_providers.dart';
import 'package:eventhub/features/events/domain/entities/event.dart';
import 'package:eventhub/features/events/presentation/widgets/event_card.dart';
import 'package:eventhub/features/events/presentation/widgets/event_filters.dart';
import 'package:eventhub/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Participant home.
///
/// Two layouts behind one screen:
///  * **browse** (no filter) — a curated feed: a hero carousel, then named
///    rails answering distinct intents, then the full catalogue. A
///    chronological wall of cards is what a database returns; sections are
///    what a product offers.
///  * **filtered** (a category or a query is active) — the rails collapse
///    into a single result list, because once a user has expressed an
///    intent, editorialising it gets in the way.
class EventListScreen extends ConsumerWidget {
  const EventListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final now = ref.watch(clockProvider)();
    final isFiltered =
        ref.watch(eventSearchQueryProvider).isNotEmpty ||
        ref.watch(eventCategoryFilterProvider) != null;

    final firstName = (user?.name ?? '').split(' ').first;
    final greeting = now.hour >= 18
        ? AppStrings.goodEvening
        : AppStrings.goodMorning;

    return AppScaffold(
      constrainWidth: false,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(upcomingEventsProvider),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: ScreenHeader(
                  eyebrow: firstName.isEmpty
                      ? AppStrings.exploreCaption
                      : '$greeting $firstName 👋',
                  title: AppStrings.exploreTitle,
                  trailing: GestureDetector(
                    onTap: () => context.go(AppRoutes.profile),
                    child: AppAvatar(name: user?.name ?? '', size: 46),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.gutter,
                  0,
                  AppSpacing.gutter,
                  AppSpacing.lg,
                ),
                sliver: SliverToBoxAdapter(
                  child: EventSearchField(
                    readOnly: true,
                    onTap: () => context.go(AppRoutes.search),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: CategoryFilterRail()),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
              if (isFiltered)
                const _FilteredResults()
              else
                const _CuratedFeed(),
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

// ---------------------------------------------------------------- curated --

class _CuratedFeed extends ConsumerWidget {
  const _CuratedFeed();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featured = ref.watch(featuredEventsProvider);
    final week = ref.watch(weekEventsProvider);
    final trending = ref.watch(trendingEventsProvider);
    final all = ref.watch(upcomingEventsProvider);

    // A single loading gate for the whole feed: showing three skeleton
    // rails that resolve at different times reads as a glitch.
    if (all.isLoading && !all.hasValue) {
      return const SliverToBoxAdapter(child: _FeedSkeleton());
    }
    if (all.hasError && !all.hasValue) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: ErrorStateView(
          message: AppStrings.connectionLost,
          onRetry: () => ref.invalidate(upcomingEventsProvider),
        ),
      );
    }

    final featuredList = featured.value ?? const <Event>[];
    final weekList = week.value ?? const <Event>[];
    final trendingList = trending.value ?? const <Event>[];
    final allList = all.value ?? const <Event>[];

    if (allList.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyStateView(
          title: AppStrings.noEventsTitle,
          message: AppStrings.noEvents,
        ),
      );
    }

    return SliverList.list(
      children: [
        if (featuredList.isNotEmpty) ...[
          const SectionHeader(
            title: AppStrings.featured,
            subtitle: AppStrings.featuredSubtitle,
          ),
          _FeaturedCarousel(events: featuredList),
          const SizedBox(height: AppSpacing.xxxl),
        ],
        if (trendingList.isNotEmpty) ...[
          const SectionHeader(
            title: AppStrings.trending,
            subtitle: AppStrings.trendingSubtitle,
          ),
          _EventRail(events: trendingList),
          const SizedBox(height: AppSpacing.xxxl),
        ],
        if (weekList.isNotEmpty) ...[
          const SectionHeader(
            title: AppStrings.thisWeek,
            subtitle: AppStrings.thisWeekSubtitle,
          ),
          _EventRail(events: weekList),
          const SizedBox(height: AppSpacing.xxxl),
        ],
        SectionHeader(
          title: AppStrings.allEvents,
          subtitle: '${allList.length} événements à venir',
        ),
        for (final event in allList) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
            child: EventCard(
              event: event,
              onTap: () => context.push(AppRoutes.eventDetailPath(event.id)),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ],
    );
  }
}

/// Edge-peeking carousel: the next card is visible by ~24 px, which is what
/// tells the user the row is swipeable without adding an arrow or a hint.
class _FeaturedCarousel extends StatefulWidget {
  const _FeaturedCarousel({required this.events});

  final List<Event> events;

  @override
  State<_FeaturedCarousel> createState() => _FeaturedCarouselState();
}

class _FeaturedCarouselState extends State<_FeaturedCarousel> {
  late final PageController _controller = PageController(
    viewportFraction: 0.88,
  );
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return Column(
      children: [
        SizedBox(
          height: 268,
          child: PageView.builder(
            controller: _controller,
            padEnds: false,
            onPageChanged: (i) => setState(() => _page = i),
            itemCount: widget.events.length,
            itemBuilder: (context, index) {
              final event = widget.events[index];
              return Padding(
                padding: EdgeInsets.only(
                  left: index == 0 ? AppSpacing.gutter : AppSpacing.sm,
                  right: AppSpacing.sm,
                ),
                child: EventCard(
                  event: event,
                  aspectRatio: 1,
                  onTap: () =>
                      context.push(AppRoutes.eventDetailPath(event.id)),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < widget.events.length; i++)
              AnimatedContainer(
                duration: AppMotion.short,
                curve: AppMotion.standard,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _page ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _page ? t.brand : t.borderStrong,
                  borderRadius: AppRadius.brPill,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _EventRail extends StatelessWidget {
  const _EventRail({required this.events});

  final List<Event> events;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 252,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
        itemCount: events.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) {
          final event = events[index];
          return EventRailCard(
            event: event,
            onTap: () => context.push(AppRoutes.eventDetailPath(event.id)),
          );
        },
      ),
    );
  }
}

// --------------------------------------------------------------- filtered --

class _FilteredResults extends ConsumerWidget {
  const _FilteredResults();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(filteredEventsProvider);

    return AsyncValueWidget(
      value: events,
      sliver: true,
      onRetry: () => ref.invalidate(upcomingEventsProvider),
      isEmpty: (list) => list.isEmpty,
      loading: const SliverToBoxAdapter(child: _FeedSkeleton()),
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
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xl),
          itemBuilder: (context, index) {
            final event = list[index];
            return EventCard(
              event: event,
              onTap: () => context.push(AppRoutes.eventDetailPath(event.id)),
            );
          },
        ),
      ),
    );
  }
}

class _FeedSkeleton extends StatelessWidget {
  const _FeedSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Skeleton(width: 160, height: 20),
          SizedBox(height: AppSpacing.lg),
          EventCardSkeleton(aspectRatio: 1.2),
          SizedBox(height: AppSpacing.xxl),
          Skeleton(width: 130, height: 20),
          SizedBox(height: AppSpacing.lg),
          EventCardSkeleton(),
        ],
      ),
    );
  }
}
