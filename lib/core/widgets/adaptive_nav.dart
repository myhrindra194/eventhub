import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/widgets/app_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// L’habillage de navigation, choisi d’après la largeur de la fenêtre.
///
/// EventHub tourne sur téléphone, tablette, web et desktop depuis une seule
/// base de code, et une barre basse est un idiome de téléphone : dans une
/// fenêtre de 1200 dp, elle place la navigation principale aussi loin du
/// pointeur que la mise en page le permet, et gâche l’espace latéral que
/// toute application desktop lui consacre. D’où :
///
///  * **< 600 dp** — la barre d'onglets [AppNavBar] en bas, d’abord pour le
///    pouce ;
///  * **600–1023 dp** — un rail d’icônes sur le bord d’attaque (tablettes,
///    fenêtres en écran partagé, petites fenêtres desktop) ;
///  * **>= 1024 dp** — le même rail, étendu avec les libellés, parce qu’à
///    cette largeur les libellés ne coûtent rien et suppriment toute
///    devinette.
///
/// Le rail est le même objet que la barre, tourné sur le côté : mêmes
/// destinations, même surface, même sélection par la teinte, même
/// retour haptique. Passer de
/// l’un à l’autre est un changement de mise en page, jamais un changement de
/// modèle — le shell conserve son état.
class AdaptiveNavigation extends StatelessWidget {
  const AdaptiveNavigation({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    required this.child,
    super.key,
  });

  /// En dessous de cette largeur, c’est la barre basse qui est utilisée.
  static const railBreakpoint = AppBreakpoints.compact;

  /// À partir de cette largeur, le rail affiche ses libellés.
  static const extendedBreakpoint = 1024.0;

  final List<NavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < railBreakpoint) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        body: child,
        bottomNavigationBar: AppNavBar(
          destinations: destinations,
          selectedIndex: selectedIndex,
          onSelected: onSelected,
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Row(
        children: [
          _NavRail(
            destinations: destinations,
            selectedIndex: selectedIndex,
            onSelected: onSelected,
            extended: width >= extendedBreakpoint,
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Navigation verticale pour les fenêtres larges.
///
/// Volontairement pas le `NavigationRail` de Material : il impose sa propre
/// géométrie de pilule et son propre rayon d’indicateur, ce qui en ferait le
/// seul endroit de l’app où un contrôle n’est pas construit sur l’échelle de
/// tokens.
class _NavRail extends StatelessWidget {
  const _NavRail({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    required this.extended,
  });

  static const _compactWidth = 84.0;
  static const _extendedWidth = 232.0;

  final List<NavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool extended;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final padding = MediaQuery.paddingOf(context);

    return Container(
      width: extended ? _extendedWidth : _compactWidth,
      padding: EdgeInsets.only(
        top: padding.top + AppSpacing.lg,
        bottom: padding.bottom + AppSpacing.lg,
        left: AppSpacing.sm,
        right: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: t.surface,
        border: Border(right: BorderSide(color: t.border, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < destinations.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: _RailButton(
                destination: destinations[i],
                selected: i == selectedIndex,
                extended: extended,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onSelected(i);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _RailButton extends StatelessWidget {
  const _RailButton({
    required this.destination,
    required this.selected,
    required this.extended,
    required this.onTap,
  });

  final NavDestination destination;
  final bool selected;
  final bool extended;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    // Sélection par la teinte, comme la barre d'onglets ; un fond de marque
    // très léger aide seulement l'œil à retrouver la ligne dans une liste
    // verticale, là où la barre basse n'en a pas besoin.
    final color = selected ? t.brand : t.textSecondary;
    final showBadge = (destination.badgeCount ?? 0) > 0;

    final icon = Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(
          selected ? destination.selectedIcon : destination.icon,
          size: 22,
          color: color,
        ),
        if (showBadge)
          Positioned(
            top: -2,
            right: -3,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: t.accent,
                shape: BoxShape.circle,
                border: Border.all(color: t.surface, width: 1.5),
              ),
            ),
          ),
      ],
    );

    return Semantics(
      selected: selected,
      button: true,
      label: destination.label,
      child: Tooltip(
        message: extended ? '' : destination.label,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.brButton,
          child: AnimatedContainer(
            duration: AppMotion.medium,
            curve: AppMotion.emphasized,
            padding: EdgeInsets.symmetric(
              horizontal: extended ? AppSpacing.md : AppSpacing.sm,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: selected ? t.brandSoft : null,
              borderRadius: AppRadius.brButton,
            ),
            child: extended
                ? Row(
                    children: [
                      icon,
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          destination.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.labelLarge?.copyWith(
                            color: color,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  )
                : Center(child: icon),
          ),
        ),
      ),
    );
  }
}
