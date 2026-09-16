import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/config/app_config.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/utils/date_formats.dart';
import 'package:eventhub/features/auth/application/auth_providers.dart';
import 'package:eventhub/features/events/application/event_providers.dart';
import 'package:eventhub/features/events/domain/entities/event.dart';
import 'package:eventhub/features/events/domain/entities/event_category.dart';
import 'package:eventhub/features/events/presentation/screens/all_events_screen.dart';
import 'package:eventhub/features/events/presentation/screens/event_list_screen.dart';
import 'package:eventhub/features/events/presentation/widgets/event_layout_toggle.dart';
import 'package:eventhub/features/events/presentation/widgets/featured_event_carousel.dart';
import 'package:eventhub/features/notifications/application/notification_providers.dart';
import 'package:eventhub/features/participant/application/recommendation_providers.dart';
import 'package:eventhub/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/fixtures.dart';

/// L'accueil Explorer monté dans un vrai `GoRouter` réduit à ses deux
/// routes : on vérifie la composition du fil (bannière, sections d'activité,
/// bascule) **et** que « Tout voir » mène bien à `/events/all` avec la
/// catégorie de la section — c'est ce câblage-là qui casserait sans bruit.
void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting(AppDateFormats.locale);
  });

  setUp(() => SharedPreferences.setMockInitialValues({}));

  // Horloge figée : les sections « Cette semaine » et « Ça se remplit vite »
  // dépendent de la date, et le fil ne doit pas changer d'un jour à l'autre.
  final now = Fixtures.now;

  Event event(String id, EventCategory category, int inDays) => Fixtures.event(
    id: id,
    startsAt: now.add(Duration(days: inDays)),
  ).copyWith(title: 'Événement $id', category: category);

  final catalogue = [
    event('a', EventCategory.concert, 20),
    event('b', EventCategory.concert, 21),
    event('c', EventCategory.sport, 22),
  ];

  Future<void> pump(WidgetTester tester, {Size size = const Size(390, 844)}) {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: AppRoutes.events,
      routes: [
        GoRoute(
          path: AppRoutes.events,
          builder: (_, __) => const EventListScreen(),
          routes: [
            GoRoute(
              path: 'all',
              builder: (_, state) => AllEventsScreen(
                initialCategory:
                    EventCategory.values.asNameMap()[state
                        .uri
                        .queryParameters[AppRoutes.categoryParam]],
              ),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          clockProvider.overrideWithValue(() => now),
          catalogueProvider.overrideWithValue(AsyncData(catalogue)),
          canLoadMoreEventsProvider.overrideWithValue(false),
          currentUserProvider.overrideWithValue(null),
          recommendedEventsProvider.overrideWithValue(const []),
          unreadNotificationCountProvider.overrideWithValue(0),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
  }

  testWidgets('bannière, bascule et une section par activité', (tester) async {
    await pump(tester);
    await tester.pump();

    expect(find.byType(FeaturedEventCarousel), findsOneWidget);
    expect(find.byType(EventLayoutToggle), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('activity-sport')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const ValueKey('activity-concert')), findsOneWidget);
    // Aucune section pour une activité sans événement.
    expect(find.byKey(const ValueKey('activity-culture')), findsNothing);

    // Démonte l'écran pour que le minuteur de la bannière soit annulé
    // avant la vérification des minuteurs en fin de test.
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('« Tout voir » ouvre le catalogue sur l’activité', (
    tester,
  ) async {
    await pump(tester);
    await tester.pump();

    final section = find.byKey(const ValueKey('activity-concert'));
    await tester.scrollUntilVisible(
      section,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(
      find.descendant(of: section, matching: find.text(AppStrings.seeAll)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AllEventsScreen), findsOneWidget);
    expect(
      find.widgetWithText(AppBar, EventCategory.concert.label),
      findsOneWidget,
    );
    expect(find.text(AllEventsCopy.count(2)), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('paysage bas : aucun débordement, en liste comme en grille', (
    tester,
  ) async {
    await pump(tester, size: const Size(640, 300));
    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(
      find.byType(EventLayoutToggle),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byTooltip(EventLayoutCopy.grid));
    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -4000));
    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
