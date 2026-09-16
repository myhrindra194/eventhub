import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/events/application/event_layout_controller.dart';
import 'package:eventhub/features/events/application/event_providers.dart';
import 'package:eventhub/features/events/domain/entities/event.dart';
import 'package:eventhub/features/events/domain/entities/event_category.dart';
import 'package:eventhub/features/events/presentation/widgets/event_collection.dart';
import 'package:eventhub/features/events/presentation/widgets/event_filters.dart';
import 'package:eventhub/features/events/presentation/widgets/event_layout_toggle.dart';
import 'package:eventhub/features/events/presentation/widgets/load_more_events_button.dart';
import 'package:eventhub/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Libellés propres à cet écran. Hors d'`AppStrings` le temps que le
/// catalogue de chaînes partagé, en cours de refonte, soit stabilisé.
abstract final class AllEventsCopy {
  static const title = 'Tous les événements';

  static String count(int n) => switch (n) {
    0 => 'Aucun événement',
    1 => '1 événement',
    _ => '$n événements',
  };
}

/// « Tous les événements » — le catalogue complet, où l'accueil n'en montre
/// qu'une sélection.
///
/// On y arrive depuis le « Tout voir » d'une section d'activité (la catégorie
/// arrive alors dans l'URL) ou depuis l'action « Tous les événements » de
/// l'accueil. L'écran reprend les outils de l'accueil — rail de catégories,
/// menu « Filtres », bascule liste / grille — pour qu'on n'ait rien à
/// réapprendre en changeant d'écran.
///
/// La catégorie est un **état local** initialisé depuis l'URL, pas le filtre
/// global de l'accueil (voir [browsableEvents]). La période, le tri et le
/// masquage des complets, eux, sont partagés : ce sont des préférences de
/// lecture, que l'utilisateur s'attend à retrouver partout.
class AllEventsScreen extends ConsumerStatefulWidget {
  const AllEventsScreen({super.key, this.initialCategory});

  final EventCategory? initialCategory;

  @override
  ConsumerState<AllEventsScreen> createState() => _AllEventsScreenState();
}

class _AllEventsScreenState extends ConsumerState<AllEventsScreen> {
  late EventCategory? _category = widget.initialCategory;

  void _open(Event event) => context.push(AppRoutes.eventDetailPath(event.id));

  @override
  Widget build(BuildContext context) {
    final events = ref.watch(browsableEventsProvider(_category));
    final layout = ref.watch(eventLayoutControllerProvider);
    final gutter = context.gutter;

    return AppScaffold(
      constrainWidth: false,
      appBar: AppTopBar.subPage(
        // Le titre suit la catégorie : l'écran dit toujours ce qu'il montre,
        // y compris après un changement de pastille.
        title: _category?.label ?? AllEventsCopy.title,
        onBack: () =>
            context.canPop() ? context.pop() : context.go(AppRoutes.events),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref
          ..invalidate(upcomingEventsProvider)
          ..invalidate(catalogueExtraPagesProvider),
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              sliver: SliverToBoxAdapter(
                child: CategoryFilterRail(
                  padding: EdgeInsets.symmetric(horizontal: gutter),
                  selected: _category,
                  onSelected: (category) =>
                      setState(() => _category = category),
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                gutter,
                AppSpacing.lg,
                gutter,
                AppSpacing.lg,
              ),
              sliver: SliverToBoxAdapter(
                child: _Toolbar(count: events.value?.length),
              ),
            ),
            AsyncValueWidget<List<Event>>(
              value: events,
              sliver: true,
              onRetry: () => ref.invalidate(upcomingEventsProvider),
              isEmpty: (list) => list.isEmpty,
              loading: SliverToBoxAdapter(
                child: EventCollectionSkeleton(layout: layout),
              ),
              empty: SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyCatalogue(
                  category: _category,
                  onShowAll: () => setState(() => _category = null),
                ),
              ),
              data: (list) => SliverEventCollection(
                events: list,
                layout: layout,
                onOpen: _open,
                footer: const LoadMoreEventsButton(),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: AppSizes.navBarInset),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compteur à gauche, « Filtres » et bascule à droite.
///
/// Le compteur est en `Expanded` avec ellipse : sur un téléphone de 300 dp,
/// c'est lui qui cède la place, jamais les commandes.
class _Toolbar extends StatelessWidget {
  const _Toolbar({required this.count});

  /// `null` pendant le chargement : on n'affiche pas un « 0 » provisoire qui
  /// ferait croire à un catalogue vide.
  final int? count;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final t = context.tokens;
    return Row(
      children: [
        Expanded(
          child: Text(
            count == null ? '' : AllEventsCopy.count(count!),
            style: text.titleSmall
                ?.merge(AppTypography.tabular)
                .copyWith(color: t.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        const FilterButton(),
        const SizedBox(width: AppSpacing.sm),
        const EventLayoutToggle(height: AppSizes.inputHeight),
      ],
    );
  }
}

class _EmptyCatalogue extends ConsumerWidget {
  const _EmptyCatalogue({required this.category, required this.onShowAll});

  final EventCategory? category;
  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasFilters =
        ref.watch(eventPeriodFilterProvider) != EventPeriod.any ||
        ref.watch(hideSoldOutProvider);

    // L'impasse doit toujours avoir une sortie, et la bonne : d'abord
    // desserrer les filtres s'il y en a, sinon élargir à toutes les
    // activités. Proposer « Effacer les filtres » quand aucun n'est actif
    // serait une action sans effet.
    final Widget? action = hasFilters
        ? AppButton.secondary(
            label: AppStrings.clearFilters,
            expand: false,
            size: AppButtonSize.medium,
            onPressed: () {
              ref
                  .read(eventPeriodFilterProvider.notifier)
                  .select(EventPeriod.any);
              ref.read(hideSoldOutProvider.notifier).set(false);
            },
          )
        : category != null
        ? AppButton.secondary(
            label: AllEventsCopy.title,
            expand: false,
            size: AppButtonSize.medium,
            onPressed: onShowAll,
          )
        : null;

    return EmptyStateView(
      icon: category == null
          ? Icons.event_busy_rounded
          : Icons.search_off_rounded,
      title: AppStrings.noEventInCategory,
      message: hasFilters || category != null
          ? AppStrings.noEventsMatch
          : AppStrings.noEvents,
      action: action,
    );
  }
}
