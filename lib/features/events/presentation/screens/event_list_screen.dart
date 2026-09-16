import 'dart:async';

import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/config/app_config.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/auth/application/auth_providers.dart';
import 'package:eventhub/features/events/application/event_providers.dart';
import 'package:eventhub/features/events/domain/entities/event.dart';
import 'package:eventhub/features/events/presentation/widgets/event_card.dart';
import 'package:eventhub/features/events/presentation/widgets/event_filters.dart';
import 'package:eventhub/features/events/presentation/widgets/load_more_events_button.dart';
import 'package:eventhub/features/notifications/presentation/widgets/notification_bell_button.dart';
import 'package:eventhub/features/participant/application/recommendation_providers.dart';
import 'package:eventhub/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Accueil participant.
///
/// Deux dispositions derrière un même écran :
///  * **parcours** (aucun filtre) — un fil éditorialisé : un carrousel
///    héros, puis des rails nommés répondant à des intentions distinctes,
///    puis le catalogue complet. Un mur chronologique de cartes, c’est ce
///    que renvoie une base de données ; des sections, c’est ce qu’offre un
///    produit.
///  * **filtré** (une catégorie ou une requête est active) — les rails se
///    replient en une seule liste de résultats, car une fois que
///    l’utilisateur a exprimé une intention, l’éditorialiser ne fait que
///    gêner.
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
      // Le salut passe en ligne de contexte de la barre : il situe la page
      // sans manger la bande de hauteur que prenait un grand titre.
      appBar: AppTopBar.root(
        title: AppStrings.exploreTitle,
        subtitle: firstName.isEmpty
            ? AppStrings.exploreCaption
            : '$greeting $firstName 👋',
        actions: [
          const NotificationBellButton(),
          const SizedBox(width: AppSpacing.sm),
          GestureDetector(
            onTap: () => context.go(AppRoutes.profile),
            child: AppAvatar(name: user?.name ?? '', size: 36),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref
          ..invalidate(upcomingEventsProvider)
          ..invalidate(catalogueExtraPagesProvider),
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.sm,
                AppSpacing.gutter,
                AppSpacing.lg,
              ),
              sliver: SliverToBoxAdapter(
                child: EventSearchBar(
                  readOnly: true,
                  onTap: () => context.go(AppRoutes.search),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: CategoryFilterRail()),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
            if (isFiltered) const _FilteredResults() else const _CuratedFeed(),
            const SliverToBoxAdapter(
              child: SizedBox(height: AppSizes.navBarInset),
            ),
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------------------- parcours --

class _CuratedFeed extends ConsumerWidget {
  const _CuratedFeed();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featured = ref.watch(featuredEventsProvider);
    final week = ref.watch(weekEventsProvider);
    final trending = ref.watch(trendingEventsProvider);
    final all = ref.watch(catalogueProvider);
    final forYou = ref.watch(recommendedEventsProvider);

    // Un seul verrou de chargement pour tout le fil : afficher trois rails
    // squelettes qui se résolvent à des instants différents se lit comme un
    // défaut d’affichage.
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
        // Le rail personnel en deuxième : le carrousel donne le ton pour
        // tout le monde, celui-ci répond à « et pour moi ? » (F-18).
        if (forYou.isNotEmpty) ...[
          const SectionHeader(
            title: AppStrings.forYou,
            subtitle: AppStrings.forYouSubtitle,
          ),
          _EventRail(events: [for (final r in forYou) r.event]),
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
        const LoadMoreEventsButton(),
      ],
    );
  }
}

/// Carrousel qui laisse dépasser le bord : la carte suivante déborde
/// d’environ 24 px, et c’est cela qui dit à l’utilisateur que la rangée se
/// balaie, sans ajouter de flèche ni d’indication.
class _FeaturedCarousel extends StatefulWidget {
  const _FeaturedCarousel({required this.events});

  final List<Event> events;

  @override
  State<_FeaturedCarousel> createState() => _FeaturedCarouselState();
}

class _FeaturedCarouselState extends State<_FeaturedCarousel> {
  /// Cadence du défilement automatique.
  ///
  /// Cinq secondes, parce que c'est à peu près le temps qu'il faut pour lire
  /// un titre, une date et un lieu. Plus court, la bannière change sous les
  /// yeux de qui la lit ; plus long, personne ne voit qu'elle bouge.
  static const _interval = Duration(seconds: 5);

  late final PageController _controller = PageController(
    viewportFraction: 0.88,
  );
  Timer? _autoScroll;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  @override
  void didUpdateWidget(covariant _FeaturedCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // La liste peut changer sous le carrousel (rafraîchissement, nouvelle
    // page) : le minuteur doit repartir sur la nouvelle longueur, sinon il
    // vise un index qui n'existe plus.
    if (oldWidget.events.length != widget.events.length) _startAutoScroll();
  }

  @override
  void dispose() {
    _autoScroll?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _autoScroll?.cancel();
    // Une seule carte ne défile pas : elle clignoterait sur place.
    if (widget.events.length < 2) return;
    _autoScroll = Timer.periodic(_interval, (_) {
      if (!mounted || !_controller.hasClients) return;
      _controller.animateToPage(
        (_page + 1) % widget.events.length,
        duration: AppMotion.slow,
        curve: AppMotion.emphasized,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return Column(
      children: [
        SizedBox(
          height: 268,
          // Le défilement automatique ne lutte jamais contre le doigt : dès
          // que l'utilisateur touche le carrousel, le minuteur s'arrête, et
          // il ne repart qu'une fois le geste terminé.
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollStartNotification &&
                  notification.dragDetails != null) {
                _autoScroll?.cancel();
              } else if (notification is ScrollEndNotification) {
                _startAutoScroll();
              }
              return false;
            },
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
                  // Les cartes voisines reculent légèrement : c'est ce
                  // décalage d'échelle, et non une ombre, qui donne au
                  // carrousel sa profondeur pendant la transition.
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      final position =
                          _controller.hasClients &&
                              _controller.position.haveDimensions
                          ? (_controller.page ?? _page.toDouble())
                          : _page.toDouble();
                      final distance = (position - index).abs().clamp(0.0, 1.0);
                      return Transform.scale(
                        scale: 1 - distance * 0.06,
                        child: Opacity(
                          opacity: 1 - distance * 0.25,
                          child: child,
                        ),
                      );
                    },
                    child: EventCard(
                      event: event,
                      aspectRatio: 1,
                      onTap: () =>
                          context.push(AppRoutes.eventDetailPath(event.id)),
                    ),
                  ),
                );
              },
            ),
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

// ----------------------------------------------------------------- filtré --

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
          itemCount: list.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xl),
          itemBuilder: (context, index) {
            if (index == list.length) return const LoadMoreEventsButton();
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
