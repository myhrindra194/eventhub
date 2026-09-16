import 'dart:async';

import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/utils/date_formats.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/events/domain/entities/event.dart';
import 'package:flutter/material.dart';

/// Bannière animée « À la une » de l'accueil.
///
/// Le motif d'Eventbrite et de Luma : quelques affiches en 16:9, qui défilent
/// seules, avec le titre posé sur la photo. Ce n'est pas un rail de plus —
/// c'est l'unique endroit de l'écran où une image occupe toute la largeur, et
/// c'est ce contraste d'échelle qui donne au fil sa hiérarchie.
///
/// Comportement :
///  * **défilement automatique** toutes les [interval], en boucle ;
///  * **pause** dès qu'un doigt (ou un pointeur) touche la bannière, ou
///    qu'une souris la survole — le carrousel ne lutte jamais contre la
///    main ; le compte à rebours repart de zéro après chaque changement de
///    page, manuel ou automatique ;
///  * **aucun** défilement automatique quand le système demande de réduire
///    les animations (`MediaQuery.disableAnimationsOf`), ni quand l'écran
///    n'est pas visible (onglet inactif, route recouverte : `TickerMode`) ;
///  * sur écran large, la page suivante **dépasse** (viewportFraction < 1),
///    ce qui dit « ça se balaie » sans flèche ni légende.
class FeaturedEventCarousel extends StatefulWidget {
  const FeaturedEventCarousel({
    required this.events,
    required this.onOpen,
    super.key,
    this.interval = defaultInterval,
  });

  /// Cinq secondes : à peu près le temps de lire un titre, une date et un
  /// lieu. Plus court, l'affiche change sous les yeux de qui la lit ; plus
  /// long, personne ne remarque que la bannière bouge.
  static const defaultInterval = Duration(seconds: 5);

  /// Au plus cinq affiches : au-delà, les dernières ne sont jamais vues et
  /// l'indicateur cesse d'être lisible d'un coup d'œil.
  static const maxEvents = 5;

  final List<Event> events;
  final ValueChanged<Event> onOpen;
  final Duration interval;

  @override
  State<FeaturedEventCarousel> createState() => _FeaturedEventCarouselState();
}

class _FeaturedEventCarouselState extends State<FeaturedEventCarousel> {
  PageController? _controller;
  double _viewportFraction = 1;
  Timer? _timer;

  /// Index réel (0 … n-1) de l'affiche courante.
  int _current = 0;

  /// Nombre de pointeurs posés : un compteur plutôt qu'un booléen, sinon le
  /// second doigt d'un pincement relancerait le défilement en se levant alors
  /// que le premier est encore posé.
  int _pointers = 0;
  bool _hovered = false;
  bool _reduceMotion = false;
  bool _visible = true;

  List<Event> get _events =>
      widget.events.take(FeaturedEventCarousel.maxEvents).toList();

  int get _count => _events.length;

  bool get _loops => _count > 1;

  /// Page virtuelle de départ. Le [PageView] est infini (`itemCount: null`)
  /// et chaque page virtuelle renvoie à `index % n` : partir loin de zéro
  /// permet de balayer vers la gauche dès la première affiche, et l'avance
  /// automatique ne « rembobine » jamais visiblement de la dernière à la
  /// première. Mille tours suffisent à ne jamais atteindre le bord.
  int get _origin => _loops ? _count * 1000 : 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _visible = TickerMode.valuesOf(context).enabled;

    // Sur téléphone, une affiche pleine largeur ; au-delà, l'affiche suivante
    // dépasse. La fraction d'un PageController est figée à sa création : on
    // en recrée donc un quand la bande de largeur change (rotation,
    // redimensionnement d'une fenêtre de bureau), en conservant l'affiche
    // courante.
    final width = MediaQuery.sizeOf(context).width;
    final fraction = width >= AppBreakpoints.medium
        ? 0.62
        : width >= AppBreakpoints.compact
        ? 0.78
        : 1.0;
    if (_controller == null || fraction != _viewportFraction) {
      final previous = _controller;
      _viewportFraction = fraction;
      _controller = PageController(
        viewportFraction: fraction,
        initialPage: _origin + _current,
      );
      // L'ancien contrôleur est encore attaché au PageView de la frame en
      // cours : le libérer maintenant lèverait une assertion.
      if (previous != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => previous.dispose());
      }
    }
    _schedule();
  }

  @override
  void didUpdateWidget(covariant FeaturedEventCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // La sélection change sous la bannière (nouveau snapshot Firestore, un
    // événement devenu complet) : si la longueur bouge, l'index virtuel ne
    // correspond plus à rien, on repart proprement de la première affiche.
    final oldCount = oldWidget.events
        .take(FeaturedEventCarousel.maxEvents)
        .length;
    if (oldCount != _count) {
      _current = 0;
      // Saut différé à la frame suivante : `jumpToPage` déclenche
      // `onPageChanged`, donc un `setState`, interdit pendant un build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final controller = _controller;
        if (mounted && controller != null && controller.hasClients) {
          controller.jumpToPage(_origin);
        }
      });
    }
    _schedule();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  bool get _canAutoAdvance =>
      _loops && !_reduceMotion && _visible && _pointers == 0 && !_hovered;

  /// (Re)programme la prochaine avance. Un minuteur ponctuel relancé à
  /// chaque changement de page, plutôt qu'un `Timer.periodic` : après un
  /// balayage manuel, l'affiche choisie reste ses cinq secondes pleines au
  /// lieu d'être chassée par un tic déjà à moitié écoulé.
  void _schedule() {
    _timer?.cancel();
    _timer = null;
    if (!_canAutoAdvance) return;
    _timer = Timer(widget.interval, _advance);
  }

  void _advance() {
    final controller = _controller;
    if (!mounted || controller == null || !controller.hasClients) return;
    final page = controller.page?.round() ?? _origin + _current;
    controller.animateToPage(
      page + 1,
      duration: AppMotion.long,
      curve: AppMotion.emphasized,
    );
  }

  void _onPageChanged(int virtualPage) {
    setState(() => _current = virtualPage % _count);
    _schedule();
  }

  void _pointerDown(PointerDownEvent _) {
    _pointers++;
    _schedule();
  }

  void _pointerUp(PointerEvent _) {
    _pointers = (_pointers - 1).clamp(0, 1 << 20);
    _schedule();
  }

  @override
  Widget build(BuildContext context) {
    final events = _events;
    if (events.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Hauteur dérivée de la largeur d'une affiche pour tenir le 16:9,
        // plafonnée : sur un bureau, une bannière de 700 px de haut
        // chasserait tout le reste du fil sous la ligne de flottaison. Le
        // plancher garde le titre lisible sur un téléphone de 300 dp.
        final pageWidth = constraints.maxWidth * _viewportFraction;
        final cardWidth = pageWidth - 2 * _pageInset(constraints.maxWidth);
        final height = (cardWidth * 9 / 16).clamp(150.0, 380.0);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: height,
              child: MouseRegion(
                onEnter: (_) {
                  _hovered = true;
                  _schedule();
                },
                onExit: (_) {
                  _hovered = false;
                  _schedule();
                },
                child: Listener(
                  onPointerDown: _pointerDown,
                  onPointerUp: _pointerUp,
                  onPointerCancel: _pointerUp,
                  child: PageView.builder(
                    controller: _controller,
                    // Sur téléphone la page occupe tout, `padEnds` ne change
                    // rien ; sur écran large il centre l'affiche courante et
                    // laisse dépasser les deux voisines, ce qui est plus
                    // équilibré qu'une affiche calée à gauche.
                    onPageChanged: _onPageChanged,
                    itemCount: _loops ? null : events.length,
                    itemBuilder: (context, index) {
                      final event = events[index % events.length];
                      return Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: _pageInset(constraints.maxWidth),
                        ),
                        child: _BannerCard(
                          event: event,
                          compact: height < 180,
                          onTap: () => widget.onOpen(event),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            if (_loops) ...[
              const SizedBox(height: AppSpacing.md),
              _PageIndicator(
                count: events.length,
                current: _current,
                animate: !_reduceMotion,
              ),
            ],
          ],
        );
      },
    );
  }

  /// Retrait de chaque page : la gouttière de l'écran quand l'affiche est
  /// pleine largeur, un demi-espacement entre deux affiches sinon — les
  /// voisines sont alors séparées par un vrai joint, pas collées.
  double _pageInset(double width) => _viewportFraction == 1
      ? (width < 360 ? 16.0 : AppSpacing.gutter)
      : AppSpacing.sm;
}

/// Une affiche : photo plein cadre, scrim en dégradé, texte blanc en bas.
///
/// Le scrim est un dégradé, pas une ombre : c'est lui seul qui garantit la
/// lisibilité du blanc quelle que soit la photo, et il reste plat — aucune
/// élévation, conformément au reste du produit. Pas de `Hero` non plus : un
/// carrousel en boucle peut construire deux fois la même affiche de part et
/// d'autre de la page courante, et deux héros de même tag font échouer la
/// transition.
class _BannerCard extends StatelessWidget {
  const _BannerCard({
    required this.event,
    required this.compact,
    required this.onTap,
  });

  final Event event;

  /// Bannière basse (petit téléphone) : le titre tient sur une ligne pour que
  /// la date et le lieu restent visibles.
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final meta =
        '${AppDateFormats.dayMonthTime(event.startsAt)} · ${event.location}';

    return Semantics(
      button: true,
      label: '${AppStrings.featured}. ${event.title}. $meta',
      // Le sous-arbre est exclu pour que le lecteur d'écran annonce une
      // phrase et non quatre fragments ; l'action d'appui doit donc être
      // reportée ici, sinon l'affiche deviendrait inactivable au toucher
      // exploratoire.
      onTap: onTap,
      excludeSemantics: true,
      child: ClipRRect(
        borderRadius: AppRadius.brButton,
        child: Material(
          color: t.surfaceSunken,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              fit: StackFit.expand,
              children: [
                EventImage(imageUrl: event.imageUrl, seed: event.id),
                DecoratedBox(decoration: BoxDecoration(gradient: t.heroScrim)),
                Positioned(
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  bottom: compact ? AppSpacing.md : AppSpacing.lg,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${AppStrings.featured} · ${event.category.label}'
                            .toUpperCase(),
                        style: text.labelSmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.78),
                          letterSpacing: 0.8,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        event.title,
                        style: (compact ? text.titleMedium : text.headlineSmall)
                            ?.copyWith(color: Colors.white, height: 1.15),
                        maxLines: compact ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        meta,
                        style: text.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.88),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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

/// Indicateur de page : des pastilles, l'active plus large.
///
/// La largeur, et non la seule couleur, porte l'état : l'indicateur reste
/// lisible pour un daltonien et sur une photo claire. Les extrémités rondes
/// sont la seule exception à la règle des 6 px, et `AppRadius` la prévoit
/// explicitement pour les points de pagination.
class _PageIndicator extends StatelessWidget {
  const _PageIndicator({
    required this.count,
    required this.current,
    required this.animate,
  });

  final int count;
  final int current;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      label: 'Affiche ${current + 1} sur $count',
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              key: ValueKey('featured-dot-$i'),
              duration: animate ? AppMotion.medium : Duration.zero,
              curve: AppMotion.emphasized,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == current ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i == current ? t.brand : t.borderStrong,
                borderRadius: AppRadius.brPill,
              ),
            ),
        ],
      ),
    );
  }
}
