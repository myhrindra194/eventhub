import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/events/application/event_providers.dart';
import 'package:eventhub/features/events/domain/entities/event_category.dart';
import 'package:eventhub/features/events/presentation/widgets/event_card.dart';
import 'package:eventhub/features/events/presentation/widgets/event_filters.dart';
import 'package:eventhub/features/events/presentation/widgets/load_more_events_button.dart';
import 'package:eventhub/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Recherche et découverte.
///
/// L'état au repos n'est pas une page vide : sans requête ni filtre, l'écran
/// devient une surface de **parcours** — la grille des catégories avec leur
/// nombre d'événements en direct. Un écran de recherche qui n'affiche rien
/// tant qu'on n'a pas tapé gâche exactement le moment où l'utilisateur ne
/// sait pas encore ce qu'il cherche.
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
      appBar: const AppTopBar.root(title: AppStrings.search),
      body: CustomScrollView(
        slivers: [
          // Recherche et filtre partagent leur ligne : ce sont deux façons de
          // répondre à la même question — réduire ce que je vois.
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              AppSpacing.sm,
              AppSpacing.gutter,
              AppSpacing.lg,
            ),
            sliver: SliverToBoxAdapter(
              child: EventSearchBar(hint: AppStrings.searchHint),
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
              child: SectionLabel(
                isIdle
                    ? AppStrings.browseByCategory
                    : count == null
                    ? AppStrings.results
                    : '${AppStrings.results} ($count)',
              ),
            ),
          ),
          if (isIdle) const _CategoryBrowser() else const _Results(),
          const SliverToBoxAdapter(
            child: SizedBox(height: AppSizes.navBarInset),
          ),
        ],
      ),
    );
  }
}

class _Results extends ConsumerWidget {
  const _Results();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;

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
          itemBuilder: (_, __) => const Skeleton(height: 96),
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
      // Les résultats sont des **lignes réglées dans une seule surface**, et
      // non une pile de cartes : une carte par résultat multiplie les filets
      // et les coins, alors qu'un balayage de liste se lit d'autant mieux que
      // rien ne sépare les items sauf un trait d'un pixel.
      data: (list) => SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
        sliver: SliverList.list(
          children: [
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius: AppRadius.brButton,
                border: Border.all(color: t.border),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < list.length; i++) ...[
                    if (i > 0) Divider(height: 1, color: t.borderSubtle),
                    EventResultTile(
                      event: list[i],
                      onTap: () =>
                          context.push(AppRoutes.eventDetailPath(list[i].id)),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const LoadMoreEventsButton(),
          ],
        ),
      ),
    );
  }
}

/// Grille des catégories, avec le nombre d'événements de chacune — c'est ce
/// compte qui transforme une grille décorative en aide à la navigation
/// (« Concert · 12 événements » dit qu'il vaut la peine d'y toucher).
class _CategoryBrowser extends ConsumerWidget {
  const _CategoryBrowser();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(catalogueProvider).value ?? const [];

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
      sliver: SliverGrid.builder(
        // `mainAxisExtent` plutôt qu'un `childAspectRatio` : le ratio faisait
        // dépendre la hauteur de la tuile de la largeur de l'écran, si bien
        // qu'un téléphone étroit ou un texte agrandi la faisait déborder
        // (« Bottom overflowed by 26 pixels »). Une hauteur fixe ne déborde
        // jamais, quelle que soit la largeur.
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          mainAxisExtent: 112,
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

/// Tuile de catégorie : un trait de sa teinte, le glyphe en petit, le nom, le
/// compte. Pas d'aplat teinté plein — sept fonds colorés côte à côte forment
/// un nuancier, pas une navigation.
class _CategoryCard extends ConsumerWidget {
  const _CategoryCard({required this.category, required this.count});

  final EventCategory category;
  final int count;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final color = category.color(context);
    final text = Theme.of(context).textTheme;

    return Material(
      color: t.surface,
      borderRadius: AppRadius.brButton,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () =>
            ref.read(eventCategoryFilterProvider.notifier).select(category),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: AppRadius.brButton,
            border: Border.all(color: t.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(width: 3, height: 16, color: color),
                  const SizedBox(width: AppSpacing.sm),
                  Icon(category.icon, size: 16, color: color),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    category.label,
                    style: text.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    count == 0
                        ? AppStrings.noEventInCategory
                        : '$count ${AppStrings.eventsLabel(count)}',
                    style: text.bodySmall?.copyWith(color: t.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
