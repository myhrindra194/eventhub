import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/config/app_config.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/auth/application/auth_providers.dart';
import 'package:eventhub/features/events/application/event_layout_controller.dart';
import 'package:eventhub/features/events/application/event_providers.dart';
import 'package:eventhub/features/events/domain/entities/event.dart';
import 'package:eventhub/features/events/presentation/widgets/event_collection.dart';
import 'package:eventhub/features/events/presentation/widgets/event_layout_toggle.dart';
import 'package:eventhub/features/events/presentation/widgets/featured_event_carousel.dart';
import 'package:eventhub/features/notifications/presentation/widgets/notification_bell_button.dart';
import 'package:eventhub/features/participant/application/recommendation_providers.dart';
import 'package:eventhub/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Accueil participant (« Explorer »).
///
/// Un fil éditorialisé, sans champ de recherche ni filtres : une bannière
/// animée en tête, des rails nommés répondant à des intentions distinctes,
/// une section par activité, puis l’accès au catalogue complet. Un mur
/// chronologique de cartes, c’est ce que renvoie une base de données ; des
/// sections, c’est ce qu’offre un produit.
///
/// **Pourquoi plus de recherche ici.** L’onglet « Recherche » et l’écran
/// « Tous les événements » portent déjà champ, filtres et rail de catégories.
/// Les répéter en tête d’Explorer faisait de l’accueil un troisième écran de
/// recherche, et le rail de catégories doublonnait les sections « Par
/// activité » juste en dessous. Explorer sert désormais celui qui n’a pas
/// encore d’intention — c’est le parti d’Airbnb et de Luma, où l’accueil
/// inspire et où la recherche vit sur sa propre surface. Conséquence
/// assumée : l’accueil ne lit plus les providers de requête et de catégorie,
/// il n’a donc plus de « mode filtré » — une requête saisie dans l’onglet
/// Recherche ne transforme plus l’accueil à distance.
///
/// **Pourquoi la bannière est toujours là.** Catalogue vide, elle montre des
/// messages éditoriaux réels (découvrir, réserver, retrouver ses billets)
/// plutôt que de disparaître ; pendant le chargement, un squelette à sa
/// taille exacte. Le haut de l’écran garde ainsi la même forme dans tous les
/// états, et un premier lancement sur une base encore vide n’affiche pas une
/// page nue.
///
/// Les sections suivent la bascule liste / grille ([EventLayoutController]) :
/// rangées horizontales par défaut, aperçu en grille sur demande.
class EventListScreen extends ConsumerWidget {
  const EventListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final now = ref.watch(clockProvider)();

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
        child: const CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),
            SliverToBoxAdapter(child: _ExploreBanner()),
            SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
            _CuratedFeed(),
            SliverToBoxAdapter(child: SizedBox(height: AppSizes.navBarInset)),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ copie --

/// Libellés propres à l’accueil, gardés privés : le catalogue de chaînes
/// partagé est en cours de refonte, et ces phrases n’existent qu’ici.
abstract final class _Copy {
  static const allEventsAction = 'Tous les événements';
  static const byActivity = 'Par activité';

  static String upcoming(int n) => '$n événement${n > 1 ? 's' : ''} à venir';

  static String showAll(int n) => 'Voir les $n événements';
}

void _openEvent(BuildContext context, Event event) =>
    context.push(AppRoutes.eventDetailPath(event.id));

// ---------------------------------------------------------------- bannière --

/// Tête de l’accueil : affiches d’événements, bannières éditoriales ou
/// squelette, selon l’état du catalogue.
///
/// Isolée dans son propre widget pour que ses reconstructions (et le
/// minuteur du carrousel) ne dépendent que du catalogue, pas des rails
/// personnalisés ni de la bascule de disposition.
class _ExploreBanner extends ConsumerWidget {
  const _ExploreBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(catalogueProvider);
    final featured = ref.watch(featuredEventsProvider).value ?? const <Event>[];

    if (all.isLoading && !all.hasValue) return const FeaturedBannerSkeleton();

    if (featured.isNotEmpty) {
      return FeaturedEventCarousel(
        events: featured,
        onOpen: (event) => _openEvent(context, event),
      );
    }

    // Catalogue vide, en erreur, ou entièrement complet : la bannière reste,
    // avec des messages produit qui mènent à de vrais écrans. Le catalogue
    // s’ouvre par `push` (on revient à l’accueil), les billets par `go` :
    // c’est un onglet de la barre de navigation, pas une page empilée.
    return EditorialBannerCarousel(
      onOpen: (banner) => switch (banner.target) {
        EditorialBannerTarget.catalogue => context.push(
          AppRoutes.allEventsPath(),
        ),
        EditorialBannerTarget.tickets => context.go(AppRoutes.reservations),
      },
    );
  }
}

// --------------------------------------------------------------- parcours --

class _CuratedFeed extends ConsumerWidget {
  const _CuratedFeed();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final week = ref.watch(weekEventsProvider);
    final trending = ref.watch(trendingEventsProvider);
    final all = ref.watch(catalogueProvider);
    final sections = ref.watch(categorySectionsProvider);
    final forYou = ref.watch(recommendedEventsProvider);
    final layout = ref.watch(eventLayoutControllerProvider);

    // Un seul verrou de chargement pour tout le fil : afficher trois rails
    // squelettes qui se résolvent à des instants différents se lit comme un
    // défaut d’affichage.
    if (all.isLoading && !all.hasValue) {
      return SliverToBoxAdapter(child: _FeedSkeleton(layout: layout));
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

    final weekList = week.value ?? const <Event>[];
    final trendingList = trending.value ?? const <Event>[];
    final allList = all.value ?? const <Event>[];
    final sectionList = sections.value ?? const <CategorySection>[];

    if (allList.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyStateView(
          title: AppStrings.noEventsTitle,
          message: AppStrings.noEvents,
        ),
      );
    }

    void open(Event event) => _openEvent(context, event);

    // Espacement entre deux sections : assez pour que chaque titre ouvre un
    // nouveau bloc, sans filet ni carte de fond pour les séparer.
    const gap = SizedBox(height: AppSpacing.xxxl);

    return SliverList.list(
      children: [
        const _FeedToolbar(),
        const SizedBox(height: AppSpacing.xl),
        // Le rail personnel en premier : la bannière donne le ton pour tout
        // le monde, celui-ci répond à « et pour moi ? » (F-18).
        if (forYou.isNotEmpty) ...[
          EventSection(
            title: AppStrings.forYou,
            subtitle: AppStrings.forYouSubtitle,
            events: [for (final r in forYou) r.event],
            layout: layout,
            onOpen: open,
          ),
          gap,
        ],
        if (trendingList.isNotEmpty) ...[
          EventSection(
            title: AppStrings.trending,
            subtitle: AppStrings.trendingSubtitle,
            events: trendingList,
            layout: layout,
            onOpen: open,
          ),
          gap,
        ],
        if (weekList.isNotEmpty) ...[
          EventSection(
            title: AppStrings.thisWeek,
            subtitle: AppStrings.thisWeekSubtitle,
            events: weekList,
            layout: layout,
            onOpen: open,
          ),
          gap,
        ],
        if (sectionList.isNotEmpty) ...[
          // Un surtitre et un filet marquent la bascule des rails
          // éditoriaux (choisis pour l’utilisateur) aux rayons par activité
          // (choisis par lui) : deux logiques différentes, qui ne doivent pas
          // se lire comme une seule suite de sections.
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.gutter),
            child: const _RuleLabel(_Copy.byActivity),
          ),
          const SizedBox(height: AppSpacing.xl),
          for (final section in sectionList) ...[
            EventSection(
              key: ValueKey('activity-${section.category.name}'),
              title: section.category.label,
              subtitle: _Copy.upcoming(section.events.length),
              events: section.events,
              layout: layout,
              onOpen: open,
              actionLabel: AppStrings.seeAll,
              onSeeAll: () => context.push(
                AppRoutes.allEventsPath(category: section.category),
              ),
            ),
            gap,
          ],
        ],
        SectionHeader(
          title: AppStrings.allEvents,
          subtitle: _Copy.upcoming(allList.length),
          padding: EdgeInsets.fromLTRB(
            context.gutter,
            0,
            context.gutter,
            AppSpacing.md,
          ),
        ),
        // Le catalogue entier ne se déroule plus sous les sections : il vit
        // sur son propre écran, avec sa bascule et sa pagination. L’accueil
        // reste un sommaire qui se termine, pas un défilement sans fond.
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.gutter),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AppButton.secondary(
                label: _Copy.showAll(allList.length),
                onPressed: () => context.push(AppRoutes.allEventsPath()),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Ligne d’outils du fil : l’accès au catalogue complet à gauche, la bascule
/// liste / grille à droite.
///
/// Placée **sous** la bannière et au-dessus des sections, parce qu’elle agit
/// sur les sections et non sur la bannière : le contrôle se trouve juste
/// au-dessus de ce qu’il transforme.
class _FeedToolbar extends StatelessWidget {
  const _FeedToolbar();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.gutter),
      child: Row(
        children: [
          Flexible(
            child: TextButton(
              onPressed: () => context.push(AppRoutes.allEventsPath()),
              style: TextButton.styleFrom(
                foregroundColor: t.brand,
                // Sans retrait horizontal, le libellé tombe exactement sur la
                // gouttière, à l’aplomb du bord de la bannière.
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, AppSizes.buttonSm),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                _Copy.allEventsAction,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const Spacer(),
          const EventLayoutToggle(),
        ],
      ),
    );
  }
}

/// Surtitre en capitales suivi d’un filet qui file jusqu’au bord.
class _RuleLabel extends StatelessWidget {
  const _RuleLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Row(
      children: [
        SectionLabel(text, color: t.textTertiary),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: Container(height: 1, color: t.borderSubtle)),
      ],
    );
  }
}

/// Squelette du fil sous la bannière, à l’empreinte de la disposition
/// active. La bannière porte son propre squelette ([FeaturedBannerSkeleton]).
class _FeedSkeleton extends StatelessWidget {
  const _FeedSkeleton({required this.layout});

  final EventLayout layout;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.gutter),
          child: const Skeleton(width: 130, height: 20),
        ),
        const SizedBox(height: AppSpacing.lg),
        EventCollectionSkeleton(layout: layout),
      ],
    );
  }
}
