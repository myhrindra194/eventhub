import 'dart:async';
import 'dart:math' as math;

import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/utils/date_formats.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/auth/presentation/widgets/event_mark.dart';
import 'package:eventhub/features/events/domain/entities/event.dart';
import 'package:flutter/material.dart';

/// Bannière animée « À la une » de l'accueil.
///
/// Le motif d'Eventbrite et de Luma : quelques affiches en 16:9, qui défilent
/// seules, avec le titre posé sur la photo. Ce n'est pas un rail de plus —
/// c'est l'unique endroit de l'écran où une image occupe toute la largeur, et
/// c'est ce contraste d'échelle qui donne au fil sa hiérarchie.
///
/// Toute la mécanique (minuteur, animations, indicateur) vit dans
/// [_BannerCarousel], partagée avec [EditorialBannerCarousel] : les deux
/// bannières doivent bouger exactement de la même façon, sinon le passage
/// d'un catalogue vide à un catalogue rempli se lirait comme deux composants
/// différents posés au même endroit.
class FeaturedEventCarousel extends StatelessWidget {
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

  /// Durée d'une transition automatique d'affiche à affiche. 600 ms avec la
  /// courbe « emphasized » : assez long pour que le glissement se lise comme
  /// un mouvement voulu, assez court pour ne pas voler de temps de lecture.
  static const transition = Duration(milliseconds: 600);

  /// Au plus cinq affiches : au-delà, les dernières ne sont jamais vues et
  /// l'indicateur cesse d'être lisible d'un coup d'œil.
  static const maxEvents = 5;

  final List<Event> events;
  final ValueChanged<Event> onOpen;
  final Duration interval;

  @override
  Widget build(BuildContext context) {
    final list = events.take(maxEvents).toList();
    if (list.isEmpty) return const SizedBox.shrink();

    return _BannerCarousel(
      count: list.length,
      interval: interval,
      slideBuilder: (context, index, motion) => _EventSlide(
        event: list[index],
        motion: motion,
        onTap: () => onOpen(list[index]),
      ),
    );
  }
}

// -------------------------------------------------------------- éditorial --

/// Destination d'une bannière éditoriale. Le widget ne navigue pas lui-même :
/// l'écran hôte traduit la cible en route, ce qui garde la bannière testable
/// sans routeur et réutilisable ailleurs qu'à l'accueil.
enum EditorialBannerTarget { catalogue, tickets }

/// Motif dessiné en fond d'une bannière éditoriale.
enum EditorialBannerGlyph { compass, calendar, ticket }

/// Fond d'une bannière éditoriale, toujours dérivé des jetons du thème pour
/// suivre le modèle de couleur choisi par l'utilisateur.
enum EditorialBannerTone { brand, accent, brandReversed }

/// Une bannière éditoriale : un message produit, pas un faux événement.
///
/// Le projet s'interdit toute donnée simulée. Quand le catalogue est vide,
/// inventer des affiches d'événements mentirait sur l'offre réelle ; ce que
/// l'on montre à la place, ce sont les promesses du produit lui-même
/// (découvrir, réserver, garder ses billets), chacune menant à un écran qui
/// existe vraiment.
@immutable
class EditorialBanner {
  const EditorialBanner({
    required this.id,
    required this.eyebrow,
    required this.title,
    required this.message,
    required this.cue,
    required this.target,
    required this.glyph,
    required this.tone,
  });

  final String id;
  final String eyebrow;
  final String title;
  final String message;

  /// Invitation à l'action, en texte seul : pas de flèche ni d'icône, la
  /// règle du produit veut des commandes purement typographiques.
  final String cue;
  final EditorialBannerTarget target;
  final EditorialBannerGlyph glyph;
  final EditorialBannerTone tone;

  /// Les trois messages de l'accueil, dans l'ordre du parcours d'un
  /// participant : trouver, réserver, présenter son billet.
  static const defaults = <EditorialBanner>[
    EditorialBanner(
      id: 'discover',
      eyebrow: 'Explorer',
      title: 'Découvrez les événements près de chez vous',
      message:
          'Concerts, conférences, sport : ce qui se prépare autour de vous.',
      cue: 'Parcourir le catalogue',
      target: EditorialBannerTarget.catalogue,
      glyph: EditorialBannerGlyph.compass,
      tone: EditorialBannerTone.brand,
    ),
    EditorialBanner(
      id: 'book',
      eyebrow: 'Réservation',
      title: 'Réservez votre place en un geste',
      message: 'Quelques appuis entre l’envie d’y aller et la place confirmée.',
      cue: 'Trouver un événement',
      target: EditorialBannerTarget.catalogue,
      glyph: EditorialBannerGlyph.calendar,
      tone: EditorialBannerTone.accent,
    ),
    EditorialBanner(
      id: 'tickets',
      eyebrow: 'Billets',
      title: 'Vos billets toujours avec vous',
      message: 'Chaque réservation garde son billet, prêt pour l’entrée.',
      cue: 'Voir mes billets',
      target: EditorialBannerTarget.tickets,
      glyph: EditorialBannerGlyph.ticket,
      tone: EditorialBannerTone.brandReversed,
    ),
  ];
}

/// Bannière de repli quand aucun événement ne peut être mis à la une.
///
/// Même empreinte, même rythme et même indicateur que
/// [FeaturedEventCarousel] : le haut de l'accueil ne change pas de forme
/// selon l'état du catalogue, seul son contenu change.
class EditorialBannerCarousel extends StatelessWidget {
  const EditorialBannerCarousel({
    required this.onOpen,
    super.key,
    this.slides = EditorialBanner.defaults,
    this.interval = FeaturedEventCarousel.defaultInterval,
  });

  final ValueChanged<EditorialBanner> onOpen;
  final List<EditorialBanner> slides;
  final Duration interval;

  @override
  Widget build(BuildContext context) {
    if (slides.isEmpty) return const SizedBox.shrink();
    return _BannerCarousel(
      count: slides.length,
      interval: interval,
      slideBuilder: (context, index, motion) => _EditorialSlide(
        banner: slides[index],
        index: index,
        count: slides.length,
        motion: motion,
        onTap: () => onOpen(slides[index]),
      ),
    );
  }
}

/// Squelette de la bannière, à son empreinte exacte (affiche + ligne de
/// l'indicateur).
///
/// Sans lui, le fil remonterait d'environ 200 dp à l'arrivée des données :
/// le saut de mise en page le plus visible de l'écran, précisément à
/// l'endroit où le regard se pose en premier.
class FeaturedBannerSkeleton extends StatelessWidget {
  const FeaturedBannerSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final geometry = _BannerGeometry.resolve(context, constraints.maxWidth);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: geometry.height,
              child: Center(
                child: SizedBox(
                  width: geometry.cardWidth,
                  height: geometry.height,
                  // Le rayon par défaut du squelette est déjà celui des
                  // boutons (6 px), identique à celui des affiches.
                  child: const Skeleton(height: double.infinity),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md + _PageIndicator.height),
          ],
        );
      },
    );
  }
}

// ------------------------------------------------------------- géométrie --

/// Dimensions d'une bannière, partagées par le carrousel et son squelette.
@immutable
class _BannerGeometry {
  const _BannerGeometry({
    required this.fraction,
    required this.inset,
    required this.cardWidth,
    required this.height,
  });

  /// Sur téléphone, une affiche pleine largeur ; au-delà, l'affiche suivante
  /// dépasse, ce qui dit « ça se balaie » sans flèche ni légende.
  static double fractionFor(double screenWidth) =>
      screenWidth >= AppBreakpoints.medium
      ? 0.62
      : screenWidth >= AppBreakpoints.compact
      ? 0.78
      : 1.0;

  static _BannerGeometry resolve(BuildContext context, double maxWidth) {
    final screen = MediaQuery.sizeOf(context);
    final fraction = fractionFor(screen.width);
    // Retrait de chaque page : la gouttière quand l'affiche est pleine
    // largeur, un demi-espacement entre deux affiches sinon — les voisines
    // sont alors séparées par un vrai joint, pas collées.
    final inset = fraction == 1
        ? (maxWidth < 360 ? 16.0 : AppSpacing.gutter)
        : AppSpacing.sm;
    final cardWidth = maxWidth * fraction - 2 * inset;
    // Hauteur dérivée de la largeur pour tenir le 16:9, plafonnée deux fois :
    // à 380 dp, sinon une bannière de bureau chasserait tout le fil sous la
    // ligne de flottaison ; et à 62 % de la hauteur d'écran, sinon un
    // téléphone en paysage (≈ 300 dp) ne verrait plus que la bannière. Le
    // plancher de 150 dp garde le titre lisible.
    final ceiling = math.max(150, math.min(380, screen.height * 0.62));
    final height = (cardWidth * 9 / 16).clamp(150.0, ceiling.toDouble());
    return _BannerGeometry(
      fraction: fraction,
      inset: inset,
      cardWidth: cardWidth,
      height: height,
    );
  }

  final double fraction;
  final double inset;
  final double cardWidth;
  final double height;

  /// En dessous de 200 dp, le texte se resserre : titre sur une ligne, sans
  /// invitation à l'action, pour que la date ou le message restent visibles.
  bool get compact => height < 200;
}

// ------------------------------------------------------------- mécanique --

/// État d'animation transmis à chaque affiche pour la frame en cours.
///
/// Des valeurs brutes plutôt que des `Animation` : toutes sont déjà
/// combinées (position du doigt, zoom lent, apparition du texte) par le
/// carrousel, qui est le seul à connaître la page courante. L'affiche n'a
/// plus qu'à les appliquer.
@immutable
class _SlideMotion {
  const _SlideMotion({
    required this.index,
    required this.zoom,
    required this.zoomAnchor,
    required this.scale,
    required this.dim,
    required this.textOpacity,
    required this.textShift,
    required this.compact,
  });

  final int index;

  /// Échelle du fond (effet « Ken Burns »), de 1.0 à 1.08.
  final double zoom;
  final Alignment zoomAnchor;

  /// Échelle de l'affiche entière : 1 au centre, ≈ 0.94 pour une voisine.
  final double scale;

  /// Opacité du voile posé sur une affiche qui n'est pas au centre.
  final double dim;
  final double textOpacity;

  /// Décalage vertical du bloc de texte, en dp (12 → 0 à l'arrivée).
  final double textShift;
  final bool compact;
}

typedef _SlideBuilder =
    Widget Function(BuildContext context, int index, _SlideMotion motion);

class _BannerCarousel extends StatefulWidget {
  const _BannerCarousel({
    required this.count,
    required this.interval,
    required this.slideBuilder,
  });

  final int count;
  final Duration interval;
  final _SlideBuilder slideBuilder;

  @override
  State<_BannerCarousel> createState() => _BannerCarouselState();
}

/// Comportement :
///  * **défilement automatique** toutes les [_BannerCarousel.interval], en
///    boucle infinie, avec une transition de 600 ms ;
///  * **pause** dès qu'un doigt (ou un pointeur) touche la bannière, ou
///    qu'une souris la survole — le carrousel ne lutte jamais contre la
///    main ; le compte à rebours repart de zéro après chaque changement de
///    page, manuel ou automatique ;
///  * **Ken Burns** : le fond de l'affiche courante grossit lentement de 8 %
///    pendant son temps d'exposition — une image fixe paraît morte à côté
///    d'une bannière qui défile, ce mouvement lent la rend vivante sans
///    attirer l'œil comme le ferait une vidéo ;
///  * **texte** : le bloc de l'affiche qui arrive apparaît en fondu et monte
///    de 12 dp juste après l'atterrissage — le glissement porte l'image, le
///    texte arrive ensuite, dans l'ordre où on les lit ;
///  * **voisines** réduites (≈ 0.94) et voilées, interpolées depuis la
///    position du `PageController` : l'effet suit le doigt au lieu de se
///    déclencher à la fin du geste ;
///  * **indicateur** : la pastille active se remplit sur la durée
///    d'exposition, c'est un vrai compte à rebours ; elle reste pleine et
///    fixe dès que l'avance automatique est suspendue ;
///  * **réduction des animations** (`MediaQuery.disableAnimationsOf`) :
///    ni avance automatique, ni zoom, ni glissement de texte ; l'indicateur
///    montre toujours la position ;
///  * rien ne tourne quand l'écran n'est pas visible (onglet inactif, route
///    recouverte : `TickerMode`).
class _BannerCarouselState extends State<_BannerCarousel>
    with TickerProviderStateMixin {
  /// Amplitude du zoom lent. Au-delà de 10 %, la photo semble « foncer » sur
  /// le lecteur ; en deçà de 5 %, le mouvement ne se perçoit plus.
  static const _zoomAmount = 0.08;

  /// Réduction d'une affiche voisine : juste assez pour dire « pas au
  /// centre » sans la transformer en vignette.
  static const _peekScale = 0.06;
  static const _peekDim = 0.45;

  /// Amplitude du glissement du texte à l'arrivée.
  static const _textRise = 12.0;

  PageController? _controller;
  double _viewportFraction = 1;
  Timer? _timer;

  /// Compte à rebours de l'affiche courante (0 → 1 sur l'intervalle) : il
  /// remplit la pastille active. Le minuteur reste la source de vérité de
  /// l'avance ; ce contrôleur n'en est que la représentation visuelle.
  late final AnimationController _countdown = AnimationController(
    vsync: this,
    duration: widget.interval,
  );

  /// Zoom lent de l'affiche courante. Il dure l'intervalle **plus** la
  /// transition, pour que l'image bouge encore pendant qu'elle sort au lieu
  /// de se figer une demi-seconde avant de partir. Il ne repart de zéro qu'au
  /// changement de page : une pause le fige, la reprise le poursuit, sans
  /// saut d'échelle visible.
  late final AnimationController _kenBurns = AnimationController(
    vsync: this,
    duration: widget.interval + FeaturedEventCarousel.transition,
  );

  /// Apparition du texte. Les 25 premiers pourcents sont un temps mort : la
  /// page change à mi-glissement, et le texte ne doit monter qu'une fois
  /// l'affiche presque posée.
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: AppMotion.xlong,
  );
  static const _revealCurve = Interval(0.25, 1, curve: AppMotion.decelerate);

  /// Index réel (0 … n-1) et page virtuelle de l'affiche courante.
  int _current = 0;
  int _currentVirtual = 0;

  /// Page sortante et le zoom qu'elle avait atteint : sans cela, l'affiche
  /// qui s'en va retomberait brutalement à l'échelle 1 en plein glissement.
  int? _previousVirtual;
  double _previousZoom = 0;

  /// Nombre de pointeurs posés : un compteur plutôt qu'un booléen, sinon le
  /// second doigt d'un pincement relancerait le défilement en se levant alors
  /// que le premier est encore posé.
  int _pointers = 0;
  bool _hovered = false;
  bool _reduceMotion = false;
  bool _visible = true;

  int get _count => widget.count;

  bool get _loops => _count > 1;

  /// Page virtuelle de départ. Le [PageView] est infini (`itemCount: null`)
  /// et chaque page virtuelle renvoie à `index % n` : partir loin de zéro
  /// permet de balayer vers la gauche dès la première affiche, et l'avance
  /// automatique ne « rembobine » jamais visiblement de la dernière à la
  /// première. Mille tours suffisent à ne jamais atteindre le bord.
  int get _origin => _loops ? _count * 1000 : 0;

  bool get _paused => _pointers > 0 || _hovered;

  bool get _canAnimate => !_reduceMotion && _visible && !_paused;

  bool get _canAutoAdvance => _loops && _canAnimate;

  @override
  void initState() {
    super.initState();
    _currentVirtual = _origin;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    _visible = TickerMode.valuesOf(context).enabled;
    if (reduceMotion != _reduceMotion || _controller == null) {
      _reduceMotion = reduceMotion;
      // Sans animation, le texte est simplement là et l'image reste à
      // l'échelle 1 ; sinon, la première affiche fait son entrée.
      if (_reduceMotion) {
        _reveal.value = 1;
        _kenBurns.value = 0;
      } else if (_controller == null) {
        _reveal.forward(from: 0);
      }
    }

    // La fraction d'un PageController est figée à sa création : on en recrée
    // donc un quand la bande de largeur change (rotation, redimensionnement
    // d'une fenêtre de bureau), en conservant l'affiche courante.
    final fraction = _BannerGeometry.fractionFor(
      MediaQuery.sizeOf(context).width,
    );
    if (_controller == null || fraction != _viewportFraction) {
      final previous = _controller;
      _viewportFraction = fraction;
      _currentVirtual = _origin + _current;
      _previousVirtual = null;
      _controller = PageController(
        viewportFraction: fraction,
        initialPage: _currentVirtual,
      );
      // L'ancien contrôleur est encore attaché au PageView de la frame en
      // cours : le libérer maintenant lèverait une assertion.
      if (previous != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => previous.dispose());
      }
    }
    _syncPlayback();
  }

  @override
  void didUpdateWidget(covariant _BannerCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.interval != widget.interval) {
      _countdown.duration = widget.interval;
      _kenBurns.duration = widget.interval + FeaturedEventCarousel.transition;
    }
    // La sélection change sous la bannière (nouveau snapshot Firestore, un
    // événement devenu complet) : si la longueur bouge, l'index virtuel ne
    // correspond plus à rien, on repart proprement de la première affiche.
    if (oldWidget.count != widget.count) {
      _current = 0;
      _currentVirtual = _origin;
      _previousVirtual = null;
      // Saut différé à la frame suivante : `jumpToPage` déclenche
      // `onPageChanged`, donc un `setState`, interdit pendant un build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final controller = _controller;
        if (mounted && controller != null && controller.hasClients) {
          controller.jumpToPage(_origin);
        }
      });
      _syncPlayback(restart: true);
    } else if (oldWidget.interval != widget.interval) {
      _syncPlayback(restart: true);
    }
    // Une simple reconstruction du parent (nouveau snapshot de même taille)
    // ne touche pas au compte à rebours : la pastille qui se remplit ne doit
    // pas repartir de zéro à chaque écriture Firestore.
  }

  @override
  void dispose() {
    _timer?.cancel();
    _countdown.dispose();
    _kenBurns.dispose();
    _reveal.dispose();
    _controller?.dispose();
    super.dispose();
  }

  /// Aligne minuteur, compte à rebours et zoom sur l'état courant.
  ///
  /// Un minuteur ponctuel relancé à chaque changement de page, plutôt qu'un
  /// `Timer.periodic` : après un balayage manuel, l'affiche choisie reste ses
  /// cinq secondes pleines au lieu d'être chassée par un tic déjà à moitié
  /// écoulé. [restart] force ce redémarrage ; sans lui, un minuteur déjà
  /// armé est laissé tel quel — c'est ce qui rend l'appel sûr depuis
  /// `didChangeDependencies`, déclenché par n'importe quel changement de
  /// `MediaQuery` (clavier, insets).
  void _syncPlayback({bool restart = false}) {
    if (_canAutoAdvance) {
      if (restart || _timer == null) {
        _timer?.cancel();
        _timer = Timer(widget.interval, _advance);
        _countdown.forward(from: 0);
      }
    } else {
      _timer?.cancel();
      _timer = null;
      _countdown.stop();
    }

    if (_canAnimate) {
      if (!_kenBurns.isAnimating && _kenBurns.value < 1) _kenBurns.forward();
    } else {
      _kenBurns.stop();
    }
  }

  void _advance() {
    _timer = null;
    final controller = _controller;
    if (!mounted || controller == null || !controller.hasClients) return;
    final page = controller.page?.round() ?? _currentVirtual;
    controller.animateToPage(
      page + 1,
      duration: FeaturedEventCarousel.transition,
      curve: AppMotion.emphasized,
    );
  }

  void _onPageChanged(int virtualPage) {
    setState(() {
      _previousVirtual = _currentVirtual;
      _previousZoom = _kenBurns.value;
      _currentVirtual = virtualPage;
      _current = virtualPage % _count;
    });
    _kenBurns.value = 0;
    if (!_reduceMotion) _reveal.forward(from: 0);
    _syncPlayback(restart: true);
  }

  void _pointerDown(PointerDownEvent _) {
    setState(() => _pointers++);
    _syncPlayback();
  }

  void _pointerUp(PointerEvent _) {
    setState(() => _pointers = math.max(0, _pointers - 1));
    _syncPlayback(restart: true);
  }

  void _setHovered(bool value) {
    setState(() => _hovered = value);
    _syncPlayback(restart: !value);
  }

  /// Distance, en pages, entre [virtualPage] et la position réelle du
  /// défilement — fractionnaire pendant un geste. Tant que le contrôleur n'a
  /// pas de dimensions (première frame), on se rabat sur la page courante.
  double _distance(int virtualPage) {
    final controller = _controller;
    var page = _currentVirtual.toDouble();
    if (controller != null &&
        controller.positions.length == 1 &&
        controller.position.hasContentDimensions) {
      page = controller.page ?? page;
    }
    return (virtualPage - page).abs();
  }

  _SlideMotion _motionFor(int virtualPage, bool compact) {
    final index = virtualPage % _count;
    final d = _distance(virtualPage).clamp(0.0, 1.0);
    final isCurrent = virtualPage == _currentVirtual;

    final zoomProgress = _reduceMotion
        ? 0.0
        : isCurrent
        ? _kenBurns.value
        : virtualPage == _previousVirtual
        ? _previousZoom
        : 0.0;
    final reveal = _reduceMotion || !isCurrent
        ? 1.0
        : _revealCurve.transform(_reveal.value);

    return _SlideMotion(
      index: index,
      zoom: 1 + _zoomAmount * zoomProgress,
      // Le point d'ancrage alterne d'une affiche à l'autre : un zoom toujours
      // centré finit par se remarquer comme un effet ; en alternant, chaque
      // image semble cadrée différemment.
      zoomAnchor: index.isEven
          ? const Alignment(0.35, -0.25)
          : const Alignment(-0.35, 0.25),
      scale: 1 - _peekScale * d,
      dim: _peekDim * d,
      // Le texte s'efface à mesure que l'affiche quitte le centre et
      // atteint zéro à mi-chemin, là précisément où la page courante change :
      // la bascule de `reveal` se fait donc sur un texte déjà invisible, sans
      // clignotement.
      textOpacity: (1 - 2 * d).clamp(0.0, 1.0) * reveal,
      textShift: (1 - reveal) * _textRise,
      compact: compact,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final geometry = _BannerGeometry.resolve(context, constraints.maxWidth);
        final animation = Listenable.merge([_controller, _kenBurns, _reveal]);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: geometry.height,
              child: MouseRegion(
                onEnter: (_) => _setHovered(true),
                onExit: (_) => _setHovered(false),
                child: Listener(
                  onPointerDown: _pointerDown,
                  onPointerUp: _pointerUp,
                  onPointerCancel: _pointerUp,
                  child: PageView.builder(
                    controller: _controller,
                    // Sur téléphone la page occupe tout, `padEnds` ne change
                    // rien ; sur écran large il centre l'affiche courante et
                    // laisse dépasser les deux voisines.
                    onPageChanged: _onPageChanged,
                    itemCount: _loops ? null : _count,
                    itemBuilder: (context, virtualPage) => Padding(
                      padding: EdgeInsets.symmetric(horizontal: geometry.inset),
                      // Un `AnimatedBuilder` par page, pas autour du
                      // `PageView` : seules les affiches construites se
                      // redessinent à chaque frame du geste.
                      child: AnimatedBuilder(
                        animation: animation,
                        builder: (context, _) {
                          final motion = _motionFor(
                            virtualPage,
                            geometry.compact,
                          );
                          return Transform.scale(
                            scale: motion.scale,
                            child: widget.slideBuilder(
                              context,
                              motion.index,
                              motion,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (_loops) ...[
              const SizedBox(height: AppSpacing.md),
              _PageIndicator(
                count: _count,
                current: _current,
                progress: _countdown,
                running: _canAutoAdvance,
                animate: !_reduceMotion,
              ),
            ],
          ],
        );
      },
    );
  }
}

// --------------------------------------------------------------- affiches --

/// Cadre commun d'une affiche : fond zoomable, scrim, texte animé, voile.
///
/// Le scrim est un dégradé, pas une ombre : c'est lui seul qui garantit la
/// lisibilité du blanc quel que soit le fond, et il reste plat — aucune
/// élévation, conformément au reste du produit. Pas de `Hero` non plus : un
/// carrousel en boucle peut construire deux fois la même affiche de part et
/// d'autre de la page courante, et deux héros de même tag font échouer la
/// transition.
class _SlideFrame extends StatelessWidget {
  const _SlideFrame({
    required this.motion,
    required this.semanticsLabel,
    required this.onTap,
    required this.background,
    required this.foreground,
    required this.ground,
    this.corner,
  });

  final _SlideMotion motion;
  final String semanticsLabel;
  final VoidCallback onTap;
  final Widget background;
  final Widget foreground;
  final Color ground;

  /// Détail posé en haut à droite, hors du bloc de texte animé.
  final Widget? corner;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      button: true,
      label: semanticsLabel,
      // Le sous-arbre est exclu pour que le lecteur d'écran annonce une
      // phrase et non quatre fragments ; l'action d'appui doit donc être
      // reportée ici, sinon l'affiche deviendrait inactivable au toucher
      // exploratoire.
      onTap: onTap,
      excludeSemantics: true,
      child: ClipRRect(
        borderRadius: AppRadius.brButton,
        child: Material(
          color: ground,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Transform.scale(
                  key: ValueKey('banner-zoom-${motion.index}'),
                  scale: motion.zoom,
                  alignment: motion.zoomAnchor,
                  child: background,
                ),
                DecoratedBox(decoration: BoxDecoration(gradient: t.heroScrim)),
                if (corner != null)
                  Positioned(
                    top: AppSpacing.md,
                    right: AppSpacing.lg,
                    child: Opacity(
                      opacity: motion.textOpacity.clamp(0.0, 1.0),
                      child: corner,
                    ),
                  ),
                Positioned(
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  bottom: motion.compact ? AppSpacing.md : AppSpacing.lg,
                  child: Opacity(
                    key: ValueKey('banner-text-${motion.index}'),
                    opacity: motion.textOpacity,
                    child: Transform.translate(
                      offset: Offset(0, motion.textShift),
                      child: Align(
                        alignment: AlignmentDirectional.bottomStart,
                        // Sur une affiche de bureau, une ligne de 900 dp ne
                        // se lit plus : le texte garde une mesure de colonne.
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: foreground,
                        ),
                      ),
                    ),
                  ),
                ),
                if (motion.dim > 0.001)
                  IgnorePointer(
                    child: ColoredBox(
                      color: t.canvas.withValues(alpha: motion.dim),
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

/// Surtitre en capitales espacées, commun aux deux types d'affiche.
class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: Theme.of(context).textTheme.labelSmall?.copyWith(
      color: Colors.white.withValues(alpha: 0.78),
      letterSpacing: 0.8,
    ),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
  );
}

/// Une affiche d'événement : photo plein cadre, texte blanc en bas.
class _EventSlide extends StatelessWidget {
  const _EventSlide({
    required this.event,
    required this.motion,
    required this.onTap,
  });

  final Event event;
  final _SlideMotion motion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final meta =
        '${AppDateFormats.dayMonthTime(event.startsAt)} · ${event.location}';
    final compact = motion.compact;

    return _SlideFrame(
      motion: motion,
      semanticsLabel: '${AppStrings.featured}. ${event.title}. $meta',
      onTap: onTap,
      ground: t.surfaceSunken,
      background: EventImage(imageUrl: event.imageUrl, seed: event.id),
      foreground: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _Eyebrow('${AppStrings.featured} · ${event.category.label}'),
          const SizedBox(height: AppSpacing.xs),
          Text(
            event.title,
            style: (compact ? text.titleMedium : text.headlineSmall)?.copyWith(
              color: Colors.white,
              height: 1.15,
            ),
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
    );
  }
}

/// Une affiche éditoriale : aplat dégradé de la marque, motif au trait
/// débordant du cadre, message produit en bas.
///
/// Le motif est volontairement **coupé** par le bord droit et surdimensionné :
/// centré et entier, il ferait écran de chargement ; rogné, il devient une
/// texture de couverture de magazine, ce qui est le registre visé.
class _EditorialSlide extends StatelessWidget {
  const _EditorialSlide({
    required this.banner,
    required this.index,
    required this.count,
    required this.motion,
    required this.onTap,
  });

  final EditorialBanner banner;
  final int index;
  final int count;
  final _SlideMotion motion;
  final VoidCallback onTap;

  LinearGradient _gradient(AppTokens t) => switch (banner.tone) {
    EditorialBannerTone.brand => t.brandGradient,
    EditorialBannerTone.accent => t.accentGradient,
    // Même teinte que la première affiche, mais la lumière vient de l'autre
    // coin : deux bannières de marque qui se suivent ne se confondent pas.
    EditorialBannerTone.brandReversed => LinearGradient(
      begin: t.brandGradient.end,
      end: t.brandGradient.begin,
      colors: t.brandGradient.colors,
      stops: t.brandGradient.stops,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final compact = motion.compact;
    String two(int n) => n.toString().padLeft(2, '0');

    return _SlideFrame(
      motion: motion,
      semanticsLabel: '${banner.eyebrow}. ${banner.title}. ${banner.message}',
      onTap: onTap,
      ground: t.brand,
      background: DecoratedBox(
        decoration: BoxDecoration(gradient: _gradient(t)),
        child: LayoutBuilder(
          builder: (context, box) {
            final size = box.maxHeight * 1.05;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  right: -size * 0.18,
                  top: -size * 0.12,
                  child: _Glyph(glyph: banner.glyph, size: size),
                ),
              ],
            );
          },
        ),
      ),
      corner: Text(
        '${two(index + 1)} / ${two(count)}',
        style: text.labelSmall
            ?.merge(AppTypography.tabular)
            .copyWith(color: Colors.white.withValues(alpha: 0.72)),
      ),
      foreground: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _Eyebrow(banner.eyebrow),
          const SizedBox(height: AppSpacing.xs),
          Text(
            banner.title,
            style: (compact ? text.titleMedium : text.headlineSmall)?.copyWith(
              color: Colors.white,
              height: 1.15,
            ),
            maxLines: compact ? 1 : 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            banner.message,
            style: text.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.88),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (!compact) ...[
            const SizedBox(height: AppSpacing.md),
            // Invitation typographique soulignée d'un filet : elle dit « ceci
            // mène quelque part » sans poser un bouton dans un bouton — toute
            // l'affiche est déjà la cible d'appui.
            DecoratedBox(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.white)),
              ),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  banner.cue,
                  style: text.labelLarge?.copyWith(color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Motif au trait d'une affiche éditoriale, en blanc translucide.
class _Glyph extends StatelessWidget {
  const _Glyph({required this.glyph, required this.size});

  final EditorialBannerGlyph glyph;
  final double size;

  /// Marque figée à son tracé complet : le carrousel anime déjà le cadre,
  /// redessiner le billet à chaque passage ferait double emploi.
  static const _drawn = AlwaysStoppedAnimation<double>(1);

  @override
  Widget build(BuildContext context) {
    final ink = Colors.white.withValues(alpha: 0.2);
    return switch (glyph) {
      EditorialBannerGlyph.ticket => EventMark(
        progress: _drawn,
        stroke: ink,
        accent: Colors.white.withValues(alpha: 0.42),
        size: size,
        strokeWidth: 4,
      ),
      EditorialBannerGlyph.compass => Icon(
        Icons.explore_outlined,
        size: size,
        color: ink,
      ),
      EditorialBannerGlyph.calendar => Icon(
        Icons.event_available_outlined,
        size: size,
        color: ink,
      ),
    };
  }
}

// ------------------------------------------------------------ indicateur --

/// Indicateur de page qui est aussi un compte à rebours.
///
/// Des pastilles, l'active plus large, et à l'intérieur de celle-ci un
/// remplissage qui progresse sur la durée d'exposition : on sait où l'on
/// est **et** quand l'affiche va changer — ce que Instagram fait pour les
/// stories, et que des points fixes ne disent pas. Quand l'avance est
/// suspendue (doigt posé, survol, écran caché, animations réduites), la
/// pastille est pleine et immobile : un remplissage figé à mi-course se
/// lirait comme un chargement bloqué.
///
/// La largeur, et non la seule couleur, porte l'état : l'indicateur reste
/// lisible pour un daltonien. Les extrémités rondes sont la seule exception
/// à la règle des 6 px, et `AppRadius` la prévoit explicitement pour les
/// points de pagination.
class _PageIndicator extends StatelessWidget {
  const _PageIndicator({
    required this.count,
    required this.current,
    required this.progress,
    required this.running,
    required this.animate,
  });

  static const height = 6.0;
  static const activeWidth = 28.0;
  static const dotWidth = 6.0;

  final int count;
  final int current;
  final Animation<double> progress;
  final bool running;
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
              width: i == current ? activeWidth : dotWidth,
              height: height,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                // Piste de la pastille active dans la teinte douce de la
                // marque : le remplissage se détache sans qu'on confonde la
                // piste avec une pastille inactive.
                color: i == current ? t.brandSoft : t.borderStrong,
                borderRadius: AppRadius.brPill,
              ),
              child: i == current
                  ? AnimatedBuilder(
                      animation: progress,
                      builder: (context, _) => FractionallySizedBox(
                        key: ValueKey('featured-progress-$i'),
                        alignment: AlignmentDirectional.centerStart,
                        widthFactor: running
                            ? progress.value.clamp(0.0, 1.0)
                            : 1,
                        child: ColoredBox(color: t.brand),
                      ),
                    )
                  : null,
            ),
        ],
      ),
    );
  }
}
