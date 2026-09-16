import 'package:eventhub/app/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Une destination de la barre de navigation flottante.
class NavDestination {
  const NavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.badgeCount,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;

  /// Compteur facultatif, rendu sous forme de pastille sur l'icône.
  final int? badgeCount;
}

/// Barre d'onglets, dessinée d'après la barre d'onglets d'iOS.
///
/// Pourquoi ce modèle plutôt que l'ancienne pastille flottante : sur un
/// téléphone, la barre d'Apple est la navigation que tout le monde sait déjà
/// lire — des cibles égales, toujours étiquetées, ancrées au bord. Ses
/// décisions, reprises une à une :
///  * **bord à bord**, sans marge ni coins : la barre appartient au cadre de
///    l'écran, pas au contenu. C'est la seule surface du produit sans les
///    6 px, parce qu'elle n'est pas un objet posé sur la page ;
///  * **même couleur que la barre du haut** ([AppTopBar]) : la surface opaque
///    `surface`, séparée du contenu par un filet d'un demi-point. Opaque et
///    non translucide, pour que les deux barres soient identiques quel que
///    soit le contenu qui passe dessous ;
///  * **chaque onglet porte son libellé**, en petit sous l'icône : on ne
///    devine jamais ce que cache une icône ;
///  * **la sélection se lit par la teinte seule** — icône pleine et libellé
///    à la couleur de la marque —, sans pastille, sans dégradé, sans ombre ;
///  * un retour haptique léger accompagne le changement d'onglet.
///
/// Les écrans réservent [AppSizes.navBarInset] en bas de leurs zones
/// défilantes, pour que le dernier élément passe au-dessus de la barre.
class AppNavBar extends StatelessWidget {
  const AppNavBar({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  final List<NavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.surface,
        border: Border(top: BorderSide(color: t.border, width: 0.5)),
      ),
      child: Padding(
        // La zone du geste d'accueil reste sous la barre, jamais sur ses
        // cibles tactiles.
        padding: EdgeInsets.only(bottom: bottom),
        child: SizedBox(
          height: AppSizes.navBarHeight,
          child: Row(
            children: [
              for (var i = 0; i < destinations.length; i++)
                Expanded(
                  child: _NavButton(
                    destination: destinations[i],
                    selected: i == selectedIndex,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onSelected(i);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final NavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final color = selected ? t.brand : t.textTertiary;

    return Semantics(
      selected: selected,
      button: true,
      label: destination.label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        // Une éclaboussure circulaire et discrète (la forme par défaut
        // d'InkResponse) plutôt qu'un rectangle : sur iOS, toucher un onglet
        // ne dessine presque rien, le changement de teinte suffit.
        radius: 28,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Icon(
              icon: selected ? destination.selectedIcon : destination.icon,
              color: color,
              badgeCount: destination.badgeCount,
            ),
            const SizedBox(height: 3),
            // 10,5 points comme les libellés d'onglets d'iOS ; l'ellipse
            // protège la barre quand l'utilisateur agrandit le texte système.
            Text(
              destination.label,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: text.labelSmall?.copyWith(
                color: color,
                fontSize: 10.5,
                letterSpacing: 0.1,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Icon extends StatelessWidget {
  const _Icon({required this.icon, required this.color, this.badgeCount});

  final IconData icon;
  final Color color;
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final showBadge = (badgeCount ?? 0) > 0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon, size: 25, color: color),
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
  }
}
