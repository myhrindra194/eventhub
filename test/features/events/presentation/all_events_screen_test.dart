import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/utils/date_formats.dart';
import 'package:eventhub/features/auth/application/auth_providers.dart';
import 'package:eventhub/features/events/application/event_layout_controller.dart';
import 'package:eventhub/features/events/application/event_providers.dart';
import 'package:eventhub/features/events/domain/entities/event.dart';
import 'package:eventhub/features/events/domain/entities/event_category.dart';
import 'package:eventhub/features/events/presentation/screens/all_events_screen.dart';
import 'package:eventhub/features/events/presentation/widgets/event_card.dart';
import 'package:eventhub/features/events/presentation/widgets/event_layout_toggle.dart';
import 'package:eventhub/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/fixtures.dart';

/// « Tous les événements » rendu sur un catalogue fixe.
///
/// Seules les sources Firestore sont remplacées — le catalogue et la
/// pagination — ainsi que l'utilisateur courant (le cœur des favoris en
/// dépend). Les providers de filtres et de disposition restent réels : c'est
/// leur effet sur l'écran qu'on veut observer.
void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting(AppDateFormats.locale);
  });

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Event event(String id, EventCategory category, {int? availablePlaces}) =>
      Fixtures.event(
        id: id,
        availablePlaces: availablePlaces,
      ).copyWith(title: 'Événement $id', category: category);

  final catalogue = [
    event('a', EventCategory.concert),
    event('b', EventCategory.concert),
    event('c', EventCategory.sport),
    event('d', EventCategory.workshop, availablePlaces: 0),
    event('e', EventCategory.meetup),
  ];

  Future<ProviderContainer> pump(
    WidgetTester tester, {
    EventCategory? category,
    AsyncValue<List<Event>>? value,
    Size size = const Size(390, 844),
  }) async {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [
        catalogueProvider.overrideWithValue(value ?? AsyncData(catalogue)),
        canLoadMoreEventsProvider.overrideWithValue(false),
        currentUserProvider.overrideWithValue(null),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: AllEventsScreen(initialCategory: category),
        ),
      ),
    );
    await tester.pump();
    return container;
  }

  testWidgets('liste tout le catalogue en grandes cartes par défaut', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text(AllEventsCopy.title), findsOneWidget);
    expect(find.text(AllEventsCopy.count(5)), findsOneWidget);
    expect(find.byType(EventCard), findsWidgets);
    expect(find.byType(EventRailCard), findsNothing);
  });

  testWidgets('la bascule passe en grille, à deux colonnes sur téléphone', (
    tester,
  ) async {
    final container = await pump(tester);

    await tester.tap(find.byTooltip(EventLayoutCopy.grid));
    await tester.pump();

    expect(container.read(eventLayoutControllerProvider), EventLayout.grid);
    expect(find.byType(EventCard), findsNothing);
    final first = tester.getTopLeft(find.byKey(const ValueKey('grid-a')));
    final second = tester.getTopLeft(find.byKey(const ValueKey('grid-b')));
    final third = tester.getTopLeft(find.byKey(const ValueKey('grid-c')));
    expect(second.dy, first.dy);
    expect(second.dx, greaterThan(first.dx));
    expect(third.dy, greaterThan(first.dy));
  });

  testWidgets('quatre colonnes sur un écran de bureau', (tester) async {
    await pump(tester, size: const Size(1280, 900));
    await tester.tap(find.byTooltip(EventLayoutCopy.grid));
    await tester.pump();

    final row = [
      for (final id in ['a', 'b', 'c', 'd'])
        tester.getTopLeft(find.byKey(ValueKey('grid-$id'))).dy,
    ];
    expect(row.toSet(), hasLength(1));
    final fifth = tester.getTopLeft(find.byKey(const ValueKey('grid-e')));
    expect(fifth.dy, greaterThan(row.first));
  });

  testWidgets('s’ouvre sur la catégorie de l’URL, et le rail la change', (
    tester,
  ) async {
    final container = await pump(tester, category: EventCategory.concert);

    // Le titre suit la catégorie, le compteur ne compte qu'elle.
    expect(find.text(AllEventsCopy.count(2)), findsOneWidget);
    expect(
      find.widgetWithText(AppBar, EventCategory.concert.label),
      findsOneWidget,
    );

    await tester.tap(find.text(AppStrings.allCategories));
    await tester.pump();
    expect(find.text(AllEventsCopy.count(5)), findsOneWidget);

    // Le choix reste local : le filtre de l'accueil n'a pas bougé.
    expect(container.read(eventCategoryFilterProvider), isNull);
  });

  testWidgets('respecte les filtres globaux', (tester) async {
    final container = await pump(tester);
    container.read(hideSoldOutProvider.notifier).set(true);
    await tester.pump();

    expect(find.text(AllEventsCopy.count(4)), findsOneWidget);
  });

  testWidgets('état vide avec une sortie', (tester) async {
    await pump(tester, category: EventCategory.culture);

    expect(find.text(AppStrings.noEventInCategory), findsWidgets);
    // Aucune option de filtre active : la sortie proposée élargit aux
    // autres activités.
    await tester.tap(find.text(AllEventsCopy.title));
    await tester.pump();
    expect(find.text(AllEventsCopy.count(5)), findsOneWidget);
  });

  testWidgets('squelettes pendant le chargement', (tester) async {
    await pump(tester, value: const AsyncLoading<List<Event>>());

    expect(find.byType(EventCardSkeleton), findsWidgets);
    expect(find.byType(EventCard), findsNothing);
  });

  // Un test par gabarit plutôt qu'une boucle dans un seul test : remonter
  // l'écran avec un nouveau conteneur laisserait le précédent programmer sa
  // libération après la fin du test.
  for (final size in const [Size(640, 300), Size(300, 600)]) {
    testWidgets('aucun débordement en ${size.width.toInt()}×'
        '${size.height.toInt()}, en liste comme en grille', (tester) async {
      await pump(tester, size: size);
      expect(tester.takeException(), isNull, reason: 'liste');

      await tester.tap(find.byTooltip(EventLayoutCopy.grid));
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'grille');

      // Fin du catalogue atteinte, grille comprise.
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -3000));
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'grille, bas de page');
    });
  }

  test('le chemin porte la catégorie en paramètre de requête', () {
    expect(AppRoutes.allEventsPath(), '/events/all');
    expect(
      AppRoutes.allEventsPath(category: EventCategory.concert),
      '/events/all?category=concert',
    );
  });
}
