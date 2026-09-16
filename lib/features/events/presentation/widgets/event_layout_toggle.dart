import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/features/events/application/event_layout_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Libellés du sélecteur. Gardés ici plutôt que dans `AppStrings` : ils ne
/// servent qu'à ce composant, et le fichier de chaînes partagé est en cours
/// de refonte par ailleurs.
abstract final class EventLayoutCopy {
  static const rows = 'Afficher en liste';
  static const grid = 'Afficher en grille';
}

/// Sélecteur liste / grille, en contrôle segmenté compact.
///
/// Deux icônes seules, et non deux boutons à libellé : ce sont des *bascules*
/// d'affichage, comme les sélecteurs de vue de Finder ou d'Airbnb, et une
/// icône de liste ou de grille se comprend plus vite que le mot. Chaque
/// segment porte donc une infobulle et une sémantique complète (libellé,
/// état sélectionné, groupe exclusif) pour qu'aucun utilisateur n'ait à
/// deviner.
///
/// Dessin : un seul cadre filaire à 6 px, un filet entre les deux segments,
/// le segment actif en aplat tonal de marque. Aucune ombre : l'état se lit à
/// la teinte, pas à un relief.
class EventLayoutToggle extends ConsumerWidget {
  const EventLayoutToggle({super.key, this.height = 40});

  /// Hauteur du contrôle, pour l'aligner sur ses voisins (40 dp dans une
  /// barre d'outils légère, 56 dp à côté du bouton « Filtres »).
  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layout = ref.watch(eventLayoutControllerProvider);
    final notifier = ref.read(eventLayoutControllerProvider.notifier);
    final t = context.tokens;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: AppRadius.brButton,
        border: Border.all(color: t.border),
      ),
      child: ClipRRect(
        // Rayon intérieur = rayon extérieur moins l'épaisseur du filet, pour
        // que l'aplat du segment actif épouse exactement l'angle du cadre.
        borderRadius: const BorderRadius.all(
          Radius.circular(AppRadius.button - 1),
        ),
        child: SizedBox(
          height: height,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Segment(
                icon: Icons.view_agenda_outlined,
                label: EventLayoutCopy.rows,
                selected: layout == EventLayout.rows,
                onTap: () => notifier.set(EventLayout.rows),
              ),
              VerticalDivider(width: 1, thickness: 1, color: t.border),
              _Segment(
                icon: Icons.grid_view_rounded,
                label: EventLayoutCopy.grid,
                selected: layout == EventLayout.grid,
                onTap: () => notifier.set(EventLayout.grid),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        child: Material(
          color: selected ? t.brandSoft : Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              // 44 dp de large : la cible tactile reste confortable même
              // quand la hauteur descend à 40 dp dans une barre d'outils.
              width: 44,
              child: Icon(
                icon,
                size: 18,
                color: selected ? t.brand : t.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
