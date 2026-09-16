import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/events/application/event_providers.dart';
import 'package:eventhub/features/events/domain/entities/event_category.dart';
import 'package:eventhub/features/events/presentation/widgets/event_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Remet tous les filtres à zéro en un appel — l’issue de secours que tout
/// résultat vide propose, pour qu’un utilisateur ne reste jamais bloqué
/// devant une liste qu’il a lui-même filtrée.
extension EventFilterReset on WidgetRef {
  void resetEventFilters() {
    read(eventSearchQueryProvider.notifier).clear();
    read(eventCategoryFilterProvider.notifier).select(null);
    read(eventPeriodFilterProvider.notifier).select(EventPeriod.any);
    read(eventSortOrderProvider.notifier).select(EventSort.dateAsc);
    read(hideSoldOutProvider.notifier).set(false);
  }
}

/// Champ de recherche relié à `eventSearchQueryProvider`.
///
/// En mode [readOnly], c’est un leurre qui navigue vers l’onglet Recherche :
/// l’accueil garde l’affordance sans payer une requête en direct à chaque
/// frappe sur le fil.
class EventSearchField extends ConsumerStatefulWidget {
  const EventSearchField({
    super.key,
    this.hint = AppStrings.searchEvents,
    this.autofocus = false,
    this.readOnly = false,
    this.onTap,
  });

  final String hint;
  final bool autofocus;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  ConsumerState<EventSearchField> createState() => _EventSearchFieldState();
}

class _EventSearchFieldState extends ConsumerState<EventSearchField> {
  late final TextEditingController _controller = TextEditingController(
    text: ref.read(eventSearchQueryProvider),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(eventSearchQueryProvider);
    // Garde le champ synchronisé quand la requête est vidée depuis ailleurs
    // (bouton de l’état vide, réinitialisation de la feuille de filtres).
    if (_controller.text != query) {
      _controller.value = TextEditingValue(
        text: query,
        selection: TextSelection.collapsed(offset: query.length),
      );
    }

    return AppSearchField(
      hint: widget.hint,
      controller: _controller,
      value: query,
      autofocus: widget.autofocus,
      readOnly: widget.readOnly,
      onTap: widget.onTap,
      onChanged: ref.read(eventSearchQueryProvider.notifier).set,
      onClear: () {
        _controller.clear();
        ref.read(eventSearchQueryProvider.notifier).clear();
      },
    );
  }
}

/// Recherche et filtres sur **une seule ligne**.
///
/// Les deux commandes répondent à la même question — « réduire ce que je
/// vois » — et les séparer sur deux lignes coûtait une bande entière de
/// hauteur sur un téléphone, tout en laissant croire que le filtre agissait
/// sur autre chose que la recherche. C'est la disposition qu'ont retenue
/// Eventbrite comme Airbnb.
class EventSearchBar extends StatelessWidget {
  const EventSearchBar({
    super.key,
    this.hint = AppStrings.searchEvents,
    this.readOnly = false,
    this.autofocus = false,
    this.onTap,
  });

  final String hint;

  /// Champ leurre de l'accueil, qui ouvre l'onglet Recherche au lieu de
  /// lancer une requête à chaque frappe.
  final bool readOnly;
  final bool autofocus;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: EventSearchField(
            hint: hint,
            readOnly: readOnly,
            autofocus: autofocus,
            onTap: onTap,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        const FilterButton(compact: true),
      ],
    );
  }
}

/// Rail horizontal de catégories.
///
/// Une pastille sélectionnée prend la teinte propre à sa catégorie plutôt
/// que la couleur de marque : au bout de deux usages, la couleur *est* la
/// catégorie, et les utilisateurs visent la couleur au lieu de lire le
/// libellé.
class CategoryFilterRail extends ConsumerWidget {
  const CategoryFilterRail({super.key, this.padding});

  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(eventCategoryFilterProvider);
    final notifier = ref.read(eventCategoryFilterProvider.notifier);
    final t = context.tokens;

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding:
            padding ??
            const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
        children: [
          _Pill(
            label: AppStrings.allCategories,
            icon: Icons.grid_view_rounded,
            color: t.brand,
            selected: selected == null,
            onTap: () => notifier.select(null),
          ),
          for (final category in EventCategory.values) ...[
            const SizedBox(width: AppSpacing.sm),
            _Pill(
              label: category.label,
              icon: category.icon,
              color: category.color(context),
              selected: selected == category,
              onTap: () => notifier.toggle(category),
            ),
          ],
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return AnimatedContainer(
      duration: AppMotion.short,
      curve: AppMotion.standard,
      decoration: BoxDecoration(
        // Sélectionnée, la pastille prend la teinte pleine de sa catégorie :
        // le contraste suffit à la désigner, sans halo porté.
        color: selected ? color : t.surface,
        borderRadius: AppRadius.brButton,
        border: Border.all(color: selected ? color : t.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.brButton,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 15,
                  color: selected ? Colors.white : t.textSecondary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: selected ? Colors.white : t.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Ouvre la feuille de filtres avancés, avec le nombre de filtres actifs.
///
/// En mode [compact], c'est un carré de la hauteur exacte du champ de
/// recherche, à côté duquel il se pose ; le compteur devient une pastille sur
/// l'icône. C'est une commande à icône seule, comme une action de barre — pas
/// un bouton à libellé, qui lui reste toujours en texte seul.
class FilterButton extends ConsumerWidget {
  const FilterButton({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(activeFilterCountProvider);
    final t = context.tokens;
    final active = count > 0;
    final foreground = active ? t.textOnBrand : t.textSecondary;

    return Material(
      color: active ? t.brand : t.surface,
      borderRadius: AppRadius.brSm,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showEventFilterSheet(context),
        child: Container(
          width: compact ? AppSizes.inputHeight : null,
          height: compact ? AppSizes.inputHeight : null,
          alignment: compact ? Alignment.center : null,
          padding: compact
              ? null
              : const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.brSm,
            border: Border.all(color: active ? t.brand : t.border),
          ),
          child: compact
              ? Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(Icons.tune_rounded, size: 20, color: foreground),
                    if (active)
                      Positioned(
                        top: -6,
                        right: -8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          decoration: BoxDecoration(
                            color: t.accent,
                            borderRadius: AppRadius.brButton,
                          ),
                          child: Text(
                            '$count',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  letterSpacing: 0,
                                ),
                          ),
                        ),
                      ),
                  ],
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.tune_rounded, size: 16, color: foreground),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      AppStrings.filters,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: active ? t.textOnBrand : t.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (active) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: AppRadius.brButton,
                        ),
                        child: Text(
                          '$count',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: t.textOnBrand,
                                letterSpacing: 0,
                              ),
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

/// Filtres avancés : période, tri, disponibilité.
///
/// Appliqués **en direct** tant que la feuille est ouverte : le nombre de
/// résultats se met à jour au fur et à mesure des réglages. Il n’y a pas
/// d’« Appliquer » qu’on pourrait oublier — le bouton principal ne fait que
/// refermer la feuille.
Future<void> showEventFilterSheet(BuildContext context) => showAppSheet<void>(
  context: context,
  builder: (context) => const _FilterSheet(),
);

class _FilterSheet extends ConsumerWidget {
  const _FilterSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(eventPeriodFilterProvider);
    final sort = ref.watch(eventSortOrderProvider);
    final hideSoldOut = ref.watch(hideSoldOutProvider);
    final count = ref.watch(filteredEventsProvider).value?.length ?? 0;
    final t = context.tokens;

    return AppSheet(
      title: AppStrings.filters,
      subtitle: '$count ${AppStrings.results.toLowerCase()}',
      actions: [
        AppButton.primary(
          label: AppStrings.applyFilters,
          onPressed: () => Navigator.of(context).pop(),
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton.ghost(
          label: AppStrings.resetFilters,
          expand: true,
          onPressed: () => ref.resetEventFilters(),
        ),
      ],
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionLabel(AppStrings.period),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final p in EventPeriod.values)
                  _Choice(
                    label: p.label,
                    selected: p == period,
                    onTap: () =>
                        ref.read(eventPeriodFilterProvider.notifier).select(p),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            const SectionLabel(AppStrings.sortBy),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final s in EventSort.values)
                  _Choice(
                    label: s.label,
                    selected: s == sort,
                    onTap: () =>
                        ref.read(eventSortOrderProvider.notifier).select(s),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            AppSurface(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              color: t.surfaceSunken,
              child: SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: hideSoldOut,
                onChanged: (_) =>
                    ref.read(hideSoldOutProvider.notifier).toggle(),
                title: Text(
                  AppStrings.onlyAvailable,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
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
      color: selected ? t.brandSoft : t.surfaceSunken,
      borderRadius: AppRadius.brButton,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.brButton,
            border: Border.all(color: selected ? t.brand : t.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                Icon(Icons.check_rounded, size: 15, color: t.brand),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: selected ? t.brand : t.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
