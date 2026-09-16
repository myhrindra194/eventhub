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
/// (avance, pause, réduction des animations) autant que sur le rendu. Le
/// temps est celui, factice, de `WidgetTester` — `pump(durée)` fait avancer
/// l'horloge sans attendre, et le framework échoue de lui-même si un
/// `Timer` survit à la destruction de l'arbre.
void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting(AppDateFormats.locale);
  });

  // Sans image : le repli dessiné d'EventImage évite tout accès réseau et
  // tout squelette animé, qui empêcherait `pumpAndSettle` de se stabiliser.
  final events = [
    for (var i = 0; i < 3; i++)
      Fixtures.event(id: 'evt-$i').copyWith(title: 'Affiche $i'),
  ];

  Future<List<Event>> pump(
    WidgetTester tester, {
    List<Event>? list,
    Size size = const Size(390, 844),
    bool reduceMotion = false,
  }) async {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final opened = <Event>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: reduceMotion),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: FeaturedEventCarousel(
              events: list ?? events,
              onOpen: opened.add,
            ),
          ),
        ),
      ),
    );
    return opened;
  }

  /// Largeur de la pastille d'index [i], marges exclues : l'active mesure
  /// 20, les autres 6 (la boîte mesurée inclut 3 dp de marge de chaque côté).
  double dotWidth(WidgetTester tester, int i) =>
      tester.getSize(find.byKey(ValueKey('featured-dot-$i'))).width - 6;

  testWidgets('affiche la première affiche et un indicateur par événement', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('Affiche 0'), findsOneWidget);
    expect(find.text('Affiche 1'), findsNothing);
    for (var i = 0; i < events.length; i++) {
      expect(find.byKey(ValueKey('featured-dot-$i')), findsOneWidget);
    }
    expect(dotWidth(tester, 0), 20);
    expect(dotWidth(tester, 1), 6);
    expect(find.bySemanticsLabel('Affiche 1 sur 3'), findsOneWidget);
  });

  testWidgets('avance seule toutes les cinq secondes, et boucle', (
    tester,
  ) async {
    await pump(tester);

    // Juste avant l'échéance, rien ne bouge.
    // (Pas de `pumpAndSettle` ici : ses pas de 100 ms franchiraient
    // l'échéance.)
    await tester.pump(const Duration(milliseconds: 4900));
    expect(find.text('Affiche 0'), findsOneWidget);
    expect(find.text('Affiche 1'), findsNothing);

    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(find.text('Affiche 1'), findsOneWidget);
    expect(dotWidth(tester, 1), 20);
    expect(dotWidth(tester, 0), 6);

    await tester.pump(FeaturedEventCarousel.defaultInterval);
    await tester.pumpAndSettle();
    expect(find.text('Affiche 2'), findsOneWidget);

    // Après la dernière, on repart sur la première — vers l'avant.
    await tester.pump(FeaturedEventCarousel.defaultInterval);
    await tester.pumpAndSettle();
    expect(find.text('Affiche 0'), findsOneWidget);
    expect(dotWidth(tester, 0), 20);
  });

  testWidgets('se met en pause tant que le doigt est posé', (tester) async {
    await pump(tester);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(FeaturedEventCarousel)),
    );
    await tester.pump(const Duration(seconds: 12));
    await tester.pumpAndSettle();
    expect(find.text('Affiche 0'), findsOneWidget);

    // Doigt levé : le compte à rebours repart de zéro.
    await gesture.up();
    await tester.pumpAndSettle();
    await tester.pump(FeaturedEventCarousel.defaultInterval);
    await tester.pumpAndSettle();
    expect(find.text('Affiche 1'), findsOneWidget);
  });

  testWidgets('réduction des animations : aucune avance automatique', (
    tester,
  ) async {
    await pump(tester, reduceMotion: true);

    await tester.pump(const Duration(seconds: 30));
    await tester.pumpAndSettle();
    expect(find.text('Affiche 0'), findsOneWidget);
    expect(dotWidth(tester, 0), 20);
  });

  testWidgets('un appui ouvre l’événement affiché', (tester) async {
    final opened = await pump(tester);

    await tester.tap(find.text('Affiche 0'));
    await tester.pump();
    expect(opened.single.id, 'evt-0');
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
    // le minuteur, le framework lèverait « A Timer is still pending » en
    // fin de test.
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

      await pump(tester, size: const Size(300, 560));
      expect(tester.takeException(), isNull);
      // Petit téléphone : 16:9 d'une affiche de 268 dp, au-dessus du plancher.
      expect(
        tester.getSize(find.byType(PageView)).height,
        closeTo(150.75, 0.01),
      );
    },
  );
}
