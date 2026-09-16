import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/utils/date_formats.dart';
import 'package:eventhub/features/events/domain/entities/event.dart';
import 'package:eventhub/features/events/presentation/widgets/featured_event_carousel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../../helpers/fixtures.dart';

/// La bannière est un composant à minuteur : ses tests portent sur le temps
/// (avance, pause, compte à rebours, zoom, réduction des animations) autant
/// que sur le rendu. Le temps est celui, factice, de `WidgetTester` —
/// `pump(durée)` fait avancer l'horloge sans attendre, et le framework échoue
/// de lui-même si un `Timer` survit à la destruction de l'arbre.
///
/// Chaque test qui laisse l'avance automatique tourner démonte l'arbre à la
/// fin : c'est ce démontage qui annule le minuteur et libère les contrôleurs
/// d'animation avant la vérification des minuteurs en attente.
void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting(AppDateFormats.locale);
  });

  // Sans image : le repli dessiné d'EventImage évite tout accès réseau et
  // tout squelette animé.
  final events = [
    for (var i = 0; i < 3; i++)
      Fixtures.event(id: 'evt-$i').copyWith(title: 'Affiche $i'),
  ];

  Future<void> mount(
    WidgetTester tester,
    Widget child, {
    Size size = const Size(390, 844),
    bool reduceMotion = false,
  }) async {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: reduceMotion),
          child: child!,
        ),
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );
  }

  Future<List<Event>> pump(
    WidgetTester tester, {
    List<Event>? list,
    Size size = const Size(390, 844),
    bool reduceMotion = false,
  }) async {
    final opened = <Event>[];
    await mount(
      tester,
      FeaturedEventCarousel(events: list ?? events, onOpen: opened.add),
      size: size,
      reduceMotion: reduceMotion,
    );
    return opened;
  }

  /// Laisse une transition de page se jouer jusqu'au bout.
  ///
  /// Pas de `pumpAndSettle` tant que l'avance automatique tourne : le compte
  /// à rebours de l'indicateur et le zoom lent sont des animations continues,
  /// l'arbre ne se « stabilise » donc jamais par construction. On avance le
  /// temps par pas explicites, au-delà de la transition (600 ms) et de
  /// l'apparition du texte (720 ms).
  Future<void> settleTransition(WidgetTester tester) async {
    for (var i = 0; i < 9; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Échéance d'une affiche puis sa transition.
  Future<void> nextPage(WidgetTester tester) async {
    await tester.pump(FeaturedEventCarousel.defaultInterval);
    await settleTransition(tester);
  }

  /// Largeur de la pastille d'index [i], marges exclues : l'active mesure
  /// 28, les autres 6 (la boîte mesurée inclut 3 dp de marge de chaque côté).
  double dotWidth(WidgetTester tester, int i) =>
      tester.getSize(find.byKey(ValueKey('featured-dot-$i'))).width - 6;

  /// Fraction remplie de la pastille active [i] (0 → 1).
  double fill(WidgetTester tester, int i) => tester
      .widget<FractionallySizedBox>(
        find.byKey(ValueKey('featured-progress-$i')),
      )
      .widthFactor!;

  /// Échelle appliquée au fond de l'affiche réelle [i].
  double zoom(WidgetTester tester, int i) => tester
      .widget<Transform>(find.byKey(ValueKey('banner-zoom-$i')).first)
      .transform
      .getMaxScaleOnAxis();

  /// Opacité du bloc de texte de l'affiche réelle [i].
  double textOpacity(WidgetTester tester, int i) => tester
      .widget<Opacity>(find.byKey(ValueKey('banner-text-$i')).first)
      .opacity;

  testWidgets('affiche la première affiche et un indicateur par événement', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('Affiche 0'), findsOneWidget);
    expect(find.text('Affiche 1'), findsNothing);
    for (var i = 0; i < events.length; i++) {
      expect(find.byKey(ValueKey('featured-dot-$i')), findsOneWidget);
    }
    expect(dotWidth(tester, 0), 28);
    expect(dotWidth(tester, 1), 6);
    expect(find.bySemanticsLabel('Affiche 1 sur 3'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('avance seule toutes les cinq secondes, et boucle', (
    tester,
  ) async {
    await pump(tester);

    // Juste avant l'échéance, rien ne bouge.
    await tester.pump(const Duration(milliseconds: 4900));
    expect(find.text('Affiche 0'), findsOneWidget);
    expect(find.text('Affiche 1'), findsNothing);

    await tester.pump(const Duration(milliseconds: 200));
    await settleTransition(tester);
    expect(find.text('Affiche 1'), findsOneWidget);
    expect(dotWidth(tester, 1), 28);
    expect(dotWidth(tester, 0), 6);

    await nextPage(tester);
    expect(find.text('Affiche 2'), findsOneWidget);

    // Après la dernière, on repart sur la première — vers l'avant.
    await nextPage(tester);
    expect(find.text('Affiche 0'), findsOneWidget);
    expect(dotWidth(tester, 0), 28);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('se met en pause tant que le doigt est posé', (tester) async {
    await pump(tester);
    await tester.pump(const Duration(seconds: 1));

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(FeaturedEventCarousel)),
    );
    await tester.pump(const Duration(seconds: 12));
    // En pause, rien ne tourne : l'arbre se stabilise.
    await tester.pumpAndSettle();
    expect(find.text('Affiche 0'), findsOneWidget);
    // La pastille active est pleine et immobile.
    expect(fill(tester, 0), 1);

    // Doigt levé : le compte à rebours repart de zéro.
    await gesture.up();
    await tester.pump();
    expect(fill(tester, 0), lessThan(0.05));
    await tester.pump(const Duration(milliseconds: 4900));
    expect(find.text('Affiche 1'), findsNothing);
    await tester.pump(const Duration(milliseconds: 200));
    await settleTransition(tester);
    expect(find.text('Affiche 1'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'l’indicateur se remplit avec le temps et repart à zéro au changement',
    (tester) async {
      await pump(tester);
      await tester.pump();
      expect(fill(tester, 0), lessThan(0.05));

      await tester.pump(const Duration(milliseconds: 2500));
      expect(fill(tester, 0), closeTo(0.5, 0.05));

      await tester.pump(const Duration(milliseconds: 2000));
      expect(fill(tester, 0), closeTo(0.9, 0.05));

      // Nouvelle page : la pastille 1 devient active et démarre vide, la 0
      // perd son remplissage.
      await tester.pump(const Duration(milliseconds: 600));
      await settleTransition(tester);
      expect(find.byKey(const ValueKey('featured-progress-0')), findsNothing);
      expect(fill(tester, 1), lessThan(0.25));

      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('zoom lent et apparition du texte sur l’affiche courante', (
    tester,
  ) async {
    await pump(tester);
    await tester.pump();
    expect(zoom(tester, 0), closeTo(1, 0.01));

    // 2,8 s sur 5,6 s de zoom : mi-course, soit ≈ 1,04.
    await tester.pump(const Duration(milliseconds: 2800));
    expect(zoom(tester, 0), closeTo(1.04, 0.01));

    // Échéance puis début de transition : dès que la page change, le texte
    // de l'affiche entrante part de zéro.
    await tester.pump(const Duration(milliseconds: 2300));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(textOpacity(tester, 1), lessThan(0.5));

    await settleTransition(tester);
    expect(textOpacity(tester, 1), closeTo(1, 0.01));
    expect(zoom(tester, 1), lessThan(1.02));

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'réduction des animations : ni avance, ni zoom, ni compte à rebours',
    (tester) async {
      await pump(tester, reduceMotion: true);

      await tester.pump(const Duration(seconds: 30));
      await tester.pumpAndSettle();
      expect(find.text('Affiche 0'), findsOneWidget);
      // L'indicateur montre toujours la position, pastille pleine.
      expect(dotWidth(tester, 0), 28);
      expect(fill(tester, 0), 1);
      expect(zoom(tester, 0), 1);
      expect(textOpacity(tester, 0), 1);
    },
  );

  testWidgets('un appui ouvre l’événement affiché', (tester) async {
    final opened = await pump(tester);

    await tester.tap(find.text('Affiche 0'));
    await tester.pump();
    expect(opened.single.id, 'evt-0');

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('un seul événement : ni boucle, ni indicateur, ni minuteur', (
    tester,
  ) async {
    await pump(tester, list: [events.first]);

    expect(find.byKey(const ValueKey('featured-dot-0')), findsNothing);
    await tester.pump(const Duration(seconds: 20));
    await tester.pumpAndSettle();
    expect(find.text('Affiche 0'), findsOneWidget);
  });

  testWidgets('aucun minuteur ne survit au démontage', (tester) async {
    await pump(tester);
    await tester.pump(const Duration(seconds: 2));

    // Démontage en plein compte à rebours : si `dispose` oubliait d'annuler
    // le minuteur ou un contrôleur, le framework lèverait « A Timer is still
    // pending » en fin de test.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 10));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'écran large et paysage bas : la voisine dépasse, sans débordement',
    (tester) async {
      await pump(tester, size: const Size(1280, 800));
      // Page courante et voisine construites : la fraction < 1 fait dépasser
      // l'affiche suivante.
      expect(find.text('Affiche 1'), findsOneWidget);
      final banner = tester.getSize(find.byType(PageView));
      expect(banner.height, lessThanOrEqualTo(380));

      await pump(tester, size: const Size(640, 300));
      expect(tester.takeException(), isNull);
      // Paysage bas : la bannière laisse voir le reste du fil.
      expect(
        tester.getSize(find.byType(PageView)).height,
        lessThanOrEqualTo(300 * 0.62),
      );

      await pump(tester, size: const Size(300, 560));
      expect(tester.takeException(), isNull);
      // Petit téléphone : 16:9 d'une affiche de 268 dp, au-dessus du plancher.
      expect(
        tester.getSize(find.byType(PageView)).height,
        closeTo(150.75, 0.01),
      );

      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  group('bannières éditoriales', () {
    testWidgets('trois messages produit, un indicateur, un appui ciblé', (
      tester,
    ) async {
      final opened = <EditorialBanner>[];
      await mount(tester, EditorialBannerCarousel(onOpen: opened.add));
      await tester.pump();

      final first = EditorialBanner.defaults.first;
      expect(find.text(first.title), findsOneWidget);
      expect(find.text('01 / 03'), findsOneWidget);
      for (var i = 0; i < EditorialBanner.defaults.length; i++) {
        expect(find.byKey(ValueKey('featured-dot-$i')), findsOneWidget);
      }

      await tester.tap(find.text(first.title));
      await tester.pump();
      expect(opened.single.target, EditorialBannerTarget.catalogue);

      // Même rythme que les affiches d'événements.
      await nextPage(tester);
      expect(find.text(EditorialBanner.defaults[1].title), findsOneWidget);
      await nextPage(tester);
      await tester.tap(find.text(EditorialBanner.defaults[2].title));
      await tester.pump();
      expect(opened.last.target, EditorialBannerTarget.tickets);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('réduction des animations : la bannière reste immobile', (
      tester,
    ) async {
      await mount(
        tester,
        EditorialBannerCarousel(onOpen: (_) {}),
        reduceMotion: true,
      );
      await tester.pump(const Duration(seconds: 20));
      await tester.pumpAndSettle();
      expect(find.text(EditorialBanner.defaults.first.title), findsOneWidget);
      expect(fill(tester, 0), 1);
      expect(zoom(tester, 0), 1);
    });

    testWidgets('responsive : aucun débordement du téléphone au bureau', (
      tester,
    ) async {
      for (final size in const [
        Size(320, 640),
        Size(390, 844),
        Size(640, 300),
        Size(900, 1200),
        Size(1440, 900),
      ]) {
        await mount(
          tester,
          EditorialBannerCarousel(onOpen: (_) {}),
          size: size,
        );
        await tester.pump(const Duration(milliseconds: 800));
        expect(tester.takeException(), isNull, reason: '$size');
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('squelette à l’empreinte exacte de la bannière', (
      tester,
    ) async {
      await mount(tester, EditorialBannerCarousel(onOpen: (_) {}));
      await tester.pump();
      final banner = tester.getSize(find.byType(EditorialBannerCarousel));

      await mount(tester, const FeaturedBannerSkeleton());
      await tester.pump();
      expect(tester.getSize(find.byType(FeaturedBannerSkeleton)), banner);

      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
