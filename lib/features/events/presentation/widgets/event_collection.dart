import 'dart:math' as math;

import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/events/application/event_layout_controller.dart';
import 'package:eventhub/features/events/domain/entities/event.dart';
import 'package:eventhub/features/events/presentation/widgets/event_card.dart';
import 'package:flutter/material.dart';

/// Nombre de colonnes d'une grille d'événements pour une largeur **utile**
/// donnée.
///
/// On mesure la largeur réellement offerte (via `LayoutBuilder`), pas celle
/// de la fenêtre : sur tablette et bureau, le rail de navigation latéral
/// mange déjà 80 dp ou plus, et une grille calculée sur la fenêtre entière
/// tasserait ses cartes. Les seuils reprennent [AppBreakpoints] pour que la
/// grille bascule au même moment que le reste de l'interface.
///
/// Deux colonnes sur téléphone, même à 300 dp : une seule colonne de petites
/// cartes n'aurait aucun intérêt face à la liste de grandes cartes.
int eventGridColumns(double width) {
  if (width >= AppBreakpoints.medium) return 4;
  if (width >= AppBreakpoints.compact) return 3;
  return 2;
}

/// Largeur maximale d'une grande carte en mode liste. Au-delà, une photo au
/// format 4:3 dépasserait la hauteur de l'écran d'un portable : la colonne
/// est centrée, comme le fil d'un réseau social sur bureau.
const double _listMaxWidth = 640;

/// Section d'accueil : un [SectionHeader] (titre, compteur, « Tout voir ») et
/// son contenu, en rangée horizontale ou en grille selon [layout].
///
/// En grille, la section ne montre qu'un **aperçu** de deux lignes : la
/// grille complète d'une section de 40 événements repousserait toutes les
/// autres sections hors de portée, et « Tout voir » existe précisément pour
/// la suite. C'est le compromis d'Airbnb : l'accueil donne un avant-goût de
/// chaque rayon, le rayon entier est à un appui.
class EventSection extends StatelessWidget {
  const EventSection({
    required this.title,
    required this.events,
    required this.layout,
    required this.onOpen,
    super.key,
    this.subtitle,
    this.actionLabel,
    this.onSeeAll,
  });

  final String title;
  final String? subtitle;
  final List<Event> events;
  final EventLayout layout;
  final ValueChanged<Event> onOpen;
  final String? actionLabel;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SectionHeader(
          title: title,
          subtitle: subtitle,
          actionLabel: onSeeAll == null ? null : actionLabel,
          onAction: onSeeAll,
          padding: EdgeInsets.fromLTRB(
            context.gutter,
            0,
            // Le bouton texte porte déjà son propre retrait : on le colle
            // davantage au bord pour que son libellé s'aligne sur la
            // gouttière, et non 8 dp en deçà.
            context.gutter - AppSpacing.sm,
            AppSpacing.md,
          ),
        ),
        switch (layout) {
          EventLayout.rows => _EventRow(events: events, onOpen: onOpen),
          EventLayout.grid => LayoutBuilder(
            builder: (context, constraints) {
              final gutter = context.gutter;
              final columns = eventGridColumns(
                constraints.maxWidth - 2 * gutter,
              );
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: gutter),
                child: EventGridRows(
                  events: events.take(columns * 2).toList(),
                  columns: columns,
                  onOpen: onOpen,
                ),
              );
            },
          ),
        },
      ],
    );
  }
}

/// Rangée horizontale de cartes compactes.
class _EventRow extends StatelessWidget {
  const _EventRow({required this.events, required this.onOpen});

  final List<Event> events;
  final ValueChanged<Event> onOpen;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // Hauteur calée sur l'empreinte d'une EventRailCard (photo de 116 dp,
      // catégorie, titre sur deux lignes réservées, lieu) avec une marge pour
      // une taille de texte système un peu agrandie.
      height: 252,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: context.gutter),
        itemCount: events.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) {
          final event = events[index];
          return EventRailCard(event: event, onTap: () => onOpen(event));
        },
      ),
    );
  }
}

/// Grille construite ligne à ligne, et non avec un `GridView`.
///
/// Une grille à ratio fixe (`childAspectRatio`) impose une hauteur à chaque
/// cellule : au premier titre sur deux lignes ou à la première taille de
/// texte agrandie, la carte déborde et Flutter peint la bande jaune. Ici
/// chaque ligne est une `Row` d'`Expanded` sans contrainte de hauteur : la
/// ligne prend la hauteur de sa plus grande carte, rien ne déborde jamais.
/// Le coût — pas de recyclage *à l'intérieur* d'une ligne — est nul pour
/// quatre cartes au plus ; le recyclage des lignes, lui, est assuré par
/// [SliverEventCollection].
class EventGridRows extends StatelessWidget {
  const EventGridRows({
    required this.events,
    required this.columns,
    required this.onOpen,
    super.key,
  });

  final List<Event> events;
  final int columns;
  final ValueChanged<Event> onOpen;

  @override
  Widget build(BuildContext context) {
    final rows = (events.length / columns).ceil();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var r = 0; r < rows; r++) ...[
          if (r > 0) const SizedBox(height: AppSpacing.md),
          _GridRow(
            events: events.skip(r * columns).take(columns).toList(),
            columns: columns,
            onOpen: onOpen,
          ),
        ],
      ],
    );
  }
}

class _GridRow extends StatelessWidget {
  const _GridRow({
    required this.events,
    required this.columns,
    required this.onOpen,
  });

  final List<Event> events;
  final int columns;
  final ValueChanged<Event> onOpen;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var c = 0; c < columns; c++) ...[
          if (c > 0) const SizedBox(width: AppSpacing.md),
          // Une ligne incomplète garde des cellules vides : la dernière carte
          // conserve la largeur de ses voisines au lieu de s'étirer.
          Expanded(
            child: c < events.length
                ? EventRailCard(
                    key: ValueKey('grid-${events[c].id}'),
                    event: events[c],
                    width: double.infinity,
                    onTap: () => onOpen(events[c]),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ],
    );
  }
}

/// Liste ou grille d'événements en sliver, pour un catalogue potentiellement
/// long (« Tous les événements », résultats filtrés).
///
///  * liste — grandes cartes [EventCard] en colonne centrée ;
///  * grille — cartes compactes, 2 à 4 colonnes selon la largeur utile.
///
/// Dans les deux cas le sliver est paresseux : seules les lignes visibles
/// sont construites, ce qui compte quand le catalogue dépasse la centaine.
/// [footer] se place après le dernier élément (le « Charger plus »).
class SliverEventCollection extends StatelessWidget {
  const SliverEventCollection({
    required this.events,
    required this.layout,
    required this.onOpen,
    super.key,
    this.footer,
  });

  final List<Event> events;
  final EventLayout layout;
  final ValueChanged<Event> onOpen;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final gutter = context.gutter;
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.crossAxisExtent - 2 * gutter;
        switch (layout) {
          case EventLayout.rows:
            final side = gutter + math.max(0, (available - _listMaxWidth) / 2);
            return SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: side),
              sliver: SliverList.separated(
                itemCount: events.length + (footer == null ? 0 : 1),
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.xl),
                itemBuilder: (context, index) {
                  if (index == events.length) return footer!;
                  final event = events[index];
                  return EventCard(event: event, onTap: () => onOpen(event));
                },
              ),
            );
          case EventLayout.grid:
            final columns = eventGridColumns(available);
            final rows = (events.length / columns).ceil();
            return SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: gutter),
              sliver: SliverList.separated(
                itemCount: rows + (footer == null ? 0 : 1),
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, index) {
                  if (index == rows) return footer!;
                  return _GridRow(
                    events: events.skip(index * columns).take(columns).toList(),
                    columns: columns,
                    onOpen: onOpen,
                  );
                },
              ),
            );
        }
      },
    );
  }
}

/// Squelette d'une collection, à l'empreinte de la disposition active : une
/// grille qui se charge montre des cellules, une liste montre de grandes
/// cartes — sans quoi l'arrivée des données ferait sauter toute la page.
class EventCollectionSkeleton extends StatelessWidget {
  const EventCollectionSkeleton({required this.layout, super.key});

  final EventLayout layout;

  @override
  Widget build(BuildContext context) {
    final gutter = context.gutter;
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth - 2 * gutter;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: gutter),
          child: switch (layout) {
            EventLayout.rows => Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _listMaxWidth),
                child: const Column(
                  children: [
                    EventCardSkeleton(),
                    SizedBox(height: AppSpacing.xl),
                    EventCardSkeleton(),
                  ],
                ),
              ),
            ),
            EventLayout.grid => Column(
              children: [
                for (var r = 0; r < 2; r++) ...[
                  if (r > 0) const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      for (var c = 0; c < eventGridColumns(available); c++) ...[
                        if (c > 0) const SizedBox(width: AppSpacing.md),
                        const Expanded(child: Skeleton(height: 200)),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          },
        );
      },
    );
  }
}
