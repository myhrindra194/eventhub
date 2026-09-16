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
    // (bouton de l’état vide, réinitialisation depuis le menu de filtres).
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
        const FilterButton(),
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
///
/// Deux modes :
///  * **lié** (par défaut) — le rail pilote le filtre global
///    [eventCategoryFilterProvider], celui de l'accueil ;
///  * **contrôlé** — quand [onSelected] est fourni, le rail affiche
///    [selected] et remonte le choix à son parent sans toucher au filtre
///    global. C'est le mode de « Tous les événements », dont la catégorie
///    est propre à l'écran (initialisée depuis l'URL) : choisir « Concert »
///    là-bas ne doit pas replier l'accueil en mode filtré au retour.
class CategoryFilterRail extends ConsumerWidget {
  const CategoryFilterRail({
    super.key,
    this.padding,
    this.selected,
    this.onSelected,
  });

  final EdgeInsetsGeometry? padding;

  /// Catégorie affichée en mode contrôlé (`null` = « Tous »). Ignorée en
  /// mode lié.
  final EventCategory? selected;

  /// Active le mode contrôlé.
  final ValueChanged<EventCategory?>? onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controlled = onSelected;
    final selected = controlled == null
        ? ref.watch(eventCategoryFilterProvider)
        : this.selected;
    final t = context.tokens;

    void select(EventCategory? category) => controlled == null
        ? ref.read(eventCategoryFilterProvider.notifier).select(category)
        : controlled(category);

    // Un second appui sur la pastille active revient à « Tous », dans les
    // deux modes.
    void toggle(EventCategory category) =>
        select(selected == category ? null : category);

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
            onTap: () => select(null),
          ),
          for (final category in EventCategory.values) ...[
            const SizedBox(width: AppSpacing.sm),
            _Pill(
              label: category.label,
              icon: category.icon,
              color: category.color(context),
              selected: selected == category,
              onTap: () => toggle(category),
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

/// Libellés propres au menu de filtres.
///
/// Gardés privés ici plutôt que dans `AppStrings` : ils n'existent que pour
/// cette commande, et le catalogue de chaînes partagé est édité en parallèle
/// par ailleurs — un conflit de fusion sur une chaîne locale ne vaut pas la
/// centralisation.
abstract final class _FilterCopy {
  static const availability = 'Disponibilité';
  static const openHint = 'Ouvre le menu des filtres';

  /// Libellé lu par un lecteur d'écran : « Filtres, 2 actifs » se comprend
  /// à l'oreille, alors que le point médian visuel serait prononcé ou avalé
  /// selon le moteur de synthèse.
  static String semantic(int count) => count == 0
      ? AppStrings.filters
      : '${AppStrings.filters}, $count ${count > 1 ? 'actifs' : 'actif'}';

  static String results(int count) =>
      '$count ${AppStrings.results.toLowerCase()}';
}

/// Commande « Filtres » posée à côté du champ de recherche, qui déploie un
/// menu ancré juste en dessous.
///
/// **Pourquoi un menu ancré et non plus une bottom sheet.** Les réglages
/// sont courts (une période, un tri, un interrupteur) : les monter dans une
/// feuille modale masquait toute la liste qu'ils sont censés affiner, et
/// sur le web ou un bureau une feuille qui surgit du bas d'une fenêtre de
/// 1 400 dp se lit comme un portage mobile. Eventbrite et Airbnb ont fait le
/// même choix sur grand écran : le menu reste attaché à ce qui l'a ouvert,
/// l'œil ne fait pas d'aller-retour. [MenuAnchor] apporte en prime la
/// navigation au clavier (flèches, Échap), la gestion du focus et la
/// fermeture au clic extérieur, qu'une surface maison aurait dû réécrire.
///
/// **Le compromis accepté.** Sur un téléphone de 320 dp, le menu occupe
/// presque toute la largeur et une bonne part de la hauteur — il reste
/// défilable par [MenuAnchor] si l'écran est trop court, mais il n'a pas la
/// place généreuse d'une feuille. C'est acceptable parce que chaque réglage
/// s'applique **en direct** : l'utilisateur ne perd rien à le refermer.
///
/// **Le bouton lui-même.** Texte seul, hauteur exacte du champ de recherche
/// pour que les deux se lisent comme une seule barre ; « Filtres · 2 »
/// quand des filtres sont actifs, ce qui explique d'un coup d'œil pourquoi
/// une liste paraît courte. L'état actif passe par la teinte de marque et
/// un filet coloré, jamais par une ombre.
class FilterButton extends ConsumerStatefulWidget {
  const FilterButton({super.key});

  @override
  ConsumerState<FilterButton> createState() => _FilterButtonState();
}

class _FilterButtonState extends ConsumerState<FilterButton> {
  final _controller = MenuController();

  /// Suivi local de l'ouverture : le `builder` de [MenuAnchor] n'est pas
  /// garanti d'être reconstruit à chaque bascule, or le bouton doit refléter
  /// l'état ouvert (filet renforcé, `expanded` en sémantique) sans délai.
  bool _open = false;

  /// Le garde `mounted` n'est pas décoratif : [MenuAnchor] referme son menu
  /// quand il est démonté (changement d'onglet, navigation), et `onClose`
  /// peut alors tomber sur un état déjà détruit.
  // ignore: avoid_positional_boolean_parameters
  void _setOpen(bool open) {
    if (mounted && _open != open) setState(() => _open = open);
  }

  void _toggle() =>
      _controller.isOpen ? _controller.close() : _controller.open();

  @override
  Widget build(BuildContext context) {
    final count = ref.watch(activeFilterCountProvider);
    final t = context.tokens;
    final active = count > 0;
    final screenWidth = MediaQuery.sizeOf(context).width;

    // Largeur du menu par bande d'écran. Sur téléphone, il épouse la
    // colonne de contenu (écran moins les deux gouttières), plafonné à
    // 360 dp pour ne pas s'étirer sur un pliable en mode portrait. Au-delà,
    // une largeur fixe : un menu qui grandirait avec la fenêtre deviendrait
    // un panneau, et perdrait la lecture « liste de choix » qui le rend
    // rapide à parcourir.
    final menuWidth = context.isExpandedScreen
        ? 340.0
        : (screenWidth - 2 * context.gutter).clamp(240.0, 360.0);

    final foreground = active ? t.brand : t.textPrimary;
    final borderColor = active
        ? t.brand
        : _open
        ? t.borderStrong
        : t.border;

    return MenuAnchor(
      controller: _controller,
      onOpen: () => _setOpen(true),
      onClose: () => _setOpen(false),
      // Le menu s'aligne sur le bord droit du bouton (point d'ancrage en
      // bas à droite, puis décalage de toute sa largeur) : le bouton vit en
      // bout de ligne, et un menu qui partirait vers la droite serait aussitôt
      // repoussé par le bord de l'écran. Les 6 dp verticaux décollent le
      // menu du filet du bouton sans casser le lien visuel.
      alignmentOffset: Offset(-menuWidth, AppSpacing.xs + 2),
      // Réserve les gouttières de l'écran : sur téléphone, le menu recalé
      // à l'intérieur de l'écran s'aligne alors exactement sur la colonne de
      // contenu au lieu de coller au bord à 8 dp.
      reservedPadding: EdgeInsets.symmetric(
        horizontal: context.gutter,
        vertical: AppSpacing.sm,
      ),
      style: MenuStyle(
        alignment: AlignmentDirectional.bottomEnd,
        backgroundColor: WidgetStatePropertyAll(t.surface),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        // Aucune ombre : la séparation d'avec la page tient au filet et au
        // contraste de la surface, conformément au reste du produit.
        elevation: const WidgetStatePropertyAll(0),
        shadowColor: const WidgetStatePropertyAll(Colors.transparent),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: AppRadius.brButton,
            side: BorderSide(color: t.border),
          ),
        ),
        padding: const WidgetStatePropertyAll(EdgeInsets.all(AppSpacing.xs)),
        minimumSize: WidgetStatePropertyAll(Size(menuWidth, 0)),
        maximumSize: WidgetStatePropertyAll(Size(menuWidth, double.infinity)),
      ),
      menuChildren: [_FilterMenu(onDone: _controller.close)],
      builder: (context, controller, _) => Semantics(
        button: true,
        expanded: _open,
        label: _FilterCopy.semantic(count),
        hint: _FilterCopy.openHint,
        excludeSemantics: true,
        child: Material(
          color: active ? t.brandSoft : t.surface,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.brButton,
            side: BorderSide(color: borderColor),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _toggle,
            child: Container(
              height: AppSizes.inputHeight,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              alignment: Alignment.center,
              child: Text.rich(
                TextSpan(
                  text: AppStrings.filters,
                  children: [
                    if (active)
                      // Le compteur est en chiffres tabulaires et en graisse
                      // plus forte : il change sous le doigt, et ne doit ni
                      // faire tressauter la largeur du bouton ni se fondre
                      // dans le libellé.
                      TextSpan(
                        text: ' · $count',
                        style: AppTypography.tabular.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                  ],
                ),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Contenu du menu : période, tri, disponibilité, puis un pied d'actions.
///
/// Les choix s'appliquent **en direct** et ne referment pas le menu
/// (`closeOnActivate: false`) : régler une période puis un tri est un seul
/// geste, et le compteur de résultats de l'en-tête sert de retour immédiat.
/// Il n'y a donc pas d'« Appliquer » qu'on pourrait oublier ; l'action de
/// droite du pied ne fait que refermer le menu.
class _FilterMenu extends ConsumerWidget {
  const _FilterMenu({required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(eventPeriodFilterProvider);
    final sort = ref.watch(eventSortOrderProvider);
    final hideSoldOut = ref.watch(hideSoldOutProvider);
    final activeCount = ref.watch(activeFilterCountProvider);
    final results = ref.watch(filteredEventsProvider).value?.length;
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // En-tête non focalisable : le titre répète « Filtres » pour les
        // lecteurs d'écran qui arrivent dans le menu sans avoir vu le bouton,
        // et le nombre de résultats rend visible l'effet de chaque réglage.
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(AppStrings.filters, style: text.titleMedium),
              const Spacer(),
              if (results != null)
                Semantics(
                  liveRegion: true,
                  child: Text(
                    _FilterCopy.results(results),
                    style: text.bodySmall
                        ?.merge(AppTypography.tabular)
                        .copyWith(color: t.textSecondary),
                  ),
                ),
            ],
          ),
        ),
        const _Hairline(),
        const _SectionTitle(AppStrings.period),
        for (final p in EventPeriod.values)
          _MenuChoice(
            label: p.label,
            selected: p == period,
            exclusive: true,
            onPressed: () =>
                ref.read(eventPeriodFilterProvider.notifier).select(p),
          ),
        const _Hairline(),
        const _SectionTitle(AppStrings.sortBy),
        for (final s in EventSort.values)
          _MenuChoice(
            label: s.label,
            selected: s == sort,
            exclusive: true,
            onPressed: () =>
                ref.read(eventSortOrderProvider.notifier).select(s),
          ),
        const _Hairline(),
        const _SectionTitle(_FilterCopy.availability),
        _MenuChoice(
          label: AppStrings.onlyAvailable,
          selected: hideSoldOut,
          exclusive: false,
          onPressed: () => ref.read(hideSoldOutProvider.notifier).toggle(),
        ),
        const _Hairline(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Row(
            children: [
              // « Réinitialiser » n'apparaît que s'il y a quelque chose à
              // réinitialiser : une action sans effet posée en permanence
              // apprend à l'œil à l'ignorer le jour où elle servirait.
              //
              // Chaque action est enveloppée d'un `IntrinsicWidth` : un
              // MenuItemButton étire sa ligne interne sur toute la largeur
              // offerte, et posé tel quel dans une Row il recevrait une
              // largeur non bornée. La mesure intrinsèque lui impose la
              // largeur de son libellé, et le `Spacer` pousse l'action de
              // clôture sur le bord droit. Le coût (une passe de mesure en
              // plus) est négligeable pour deux libellés courts.
              if (activeCount > 0)
                IntrinsicWidth(
                  child: _MenuTextAction(
                    label: AppStrings.resetFilters,
                    color: t.textSecondary,
                    closeOnActivate: false,
                    onPressed: ref.resetEventFilters,
                  ),
                ),
              const Spacer(),
              IntrinsicWidth(
                child: _MenuTextAction(
                  label: AppStrings.applyFilters,
                  color: t.brand,
                  closeOnActivate: true,
                  onPressed: onDone,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Filet d'un pixel entre deux sections — la seule séparation du menu,
/// puisqu'il n'a ni ombre ni fonds alternés.
class _Hairline extends StatelessWidget {
  const _Hairline();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
    child: Divider(height: 1, thickness: 1, color: context.tokens.borderSubtle),
  );
}

/// Intitulé de section, en petites capitales espacées : il se lit comme une
/// étiquette de rangement, pas comme une option qu'on pourrait activer.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.sm,
      AppSpacing.lg,
      AppSpacing.xs,
    ),
    child: Semantics(header: true, child: SectionLabel(label)),
  );
}

/// Une option du menu, cochée quand elle est active.
///
/// La coche est en fin de ligne, et une réserve de même largeur la remplace
/// quand l'option est inactive : les libellés restent alignés sur une seule
/// verticale, et rien ne se décale quand la sélection change. [exclusive]
/// distingue un choix parmi plusieurs (période, tri) d'un interrupteur
/// (complets masqués) — la différence est portée jusqu'à la sémantique, pour
/// qu'un lecteur d'écran annonce « sélectionné » dans un groupe exclusif et
/// « coché » pour une case.
class _MenuChoice extends StatelessWidget {
  const _MenuChoice({
    required this.label,
    required this.selected,
    required this.exclusive,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final bool exclusive;
  final VoidCallback onPressed;

  static const _checkSize = 18.0;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      selected: exclusive ? selected : null,
      checked: selected,
      inMutuallyExclusiveGroup: exclusive ? true : null,
      child: MenuItemButton(
        closeOnActivate: false,
        onPressed: onPressed,
        style: _menuItemStyle(context),
        trailingIcon: selected
            ? Icon(Icons.check_rounded, size: _checkSize, color: t.brand)
            : const SizedBox.square(dimension: _checkSize),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: selected ? t.textPrimary : t.textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

/// Action textuelle du pied de menu — texte seul, sans icône, comme tous
/// les boutons du produit.
class _MenuTextAction extends StatelessWidget {
  const _MenuTextAction({
    required this.label,
    required this.color,
    required this.closeOnActivate,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final bool closeOnActivate;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => MenuItemButton(
    closeOnActivate: closeOnActivate,
    onPressed: onPressed,
    style: _menuItemStyle(context),
    child: Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: color,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

/// Style commun des lignes du menu : arête à 6 px, survol et focus teintés
/// par un fond discret plutôt que par l'encre Material par défaut, qui
/// paraissait délavée sur la surface claire.
ButtonStyle _menuItemStyle(BuildContext context) {
  final t = context.tokens;
  return MenuItemButton.styleFrom(
    shape: const RoundedRectangleBorder(borderRadius: AppRadius.brButton),
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
    minimumSize: const Size(0, 44),
    overlayColor: t.surfaceSunken,
    foregroundColor: t.textPrimary,
    iconColor: t.brand,
  );
}
