import 'dart:ui';

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

/// Barre de navigation flottante et floutée.
///
/// Les décisions de design méritent d'être énoncées, parce que ce sont elles
/// qui lui donnent l'air fini plutôt que par défaut :
///  * elle **flotte**, avec une marge, au lieu de coller au bord de l'écran :
///    le contenu défile visiblement dessous et l'application paraît
///    stratifiée ;
///  * seule la destination active affiche son libellé, dans une pastille
///    dégradée — le mot apparaît là où l'œil se trouve déjà, et la barre
///    reste lisible à quatre entrées ;
///  * la transition est un unique conteneur animé : changer d'onglet se lit
///    comme un objet qui se déplace, non comme quatre objets qui clignotent ;
///  * un retour haptique léger accompagne la sélection — sur un téléphone,
///    une navigation sans retour physique paraît lente même quand elle ne
///    l'est pas.
///
/// Les écrans doivent réserver [AppSizes.navBarInset] en bas de leurs zones
/// défilantes, pour que le dernier élément passe sous la barre sans être
/// masqué.
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

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        bottom + AppSpacing.md,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.brButton,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: AppSizes.navBarHeight,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            decoration: BoxDecoration(
              color: t.glass,
              // 6 px, comme tout le reste du produit. La barre se détache par
              // son flou et son filet, jamais par une ombre portée.
              borderRadius: AppRadius.brButton,
              border: Border.all(color: t.borderStrong),
            ),
            child: Row(
              children: [
                for (var i = 0; i < destinations.length; i++)
                  // La destination active est la seule à porter un libellé :
                  // il lui faut donc plus de place qu'aux autres. Des
                  // `Expanded` de parts égales débordent dès quatre
                  // destinations sur un écran de 360 dp — ce que l'on
                  // découvre en lançant l'application, jamais par l'analyseur.
                  Expanded(
                    flex: i == selectedIndex ? 2 : 1,
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
    final color = selected ? t.textOnBrand : t.textSecondary;

    return Semantics(
      selected: selected,
      button: true,
      label: destination.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brButton,
        child: Center(
          child: AnimatedContainer(
            duration: AppMotion.medium,
            curve: AppMotion.emphasized,
            padding: EdgeInsets.symmetric(
              horizontal: selected ? AppSpacing.md : AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              // La pastille active se signale par son dégradé seul : une
              // lueur portée à l'intérieur d'une barre déjà floutée se lit
              // comme une salissure, pas comme une élévation.
              gradient: selected ? t.brandGradient : null,
              borderRadius: AppRadius.brButton,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Icon(
                  icon: selected ? destination.selectedIcon : destination.icon,
                  color: color,
                  badgeCount: destination.badgeCount,
                ),
                if (selected) ...[
                  const SizedBox(width: AppSpacing.sm),
                  // `Flexible` et l'ellipse forment le filet de sécurité :
                  // quelle que soit la longueur du libellé ou la taille de
                  // texte choisie par l'utilisateur, la pastille se rétrécit
                  // au lieu de déborder de son emplacement.
                  Flexible(
                    child: Text(
                      destination.label,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: text.labelLarge?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
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
        Icon(icon, size: 22, color: color),
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
                border: Border.all(color: t.glass, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }
}
