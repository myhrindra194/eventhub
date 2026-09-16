import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/config/app_config.dart';
import 'package:eventhub/core/config/flavor.dart';
import 'package:eventhub/core/utils/date_formats.dart';
import 'package:eventhub/features/organizer/application/organizer_providers.dart';
import 'package:eventhub/features/organizer/domain/organizer_insights.dart';
import 'package:eventhub/features/organizer/presentation/screens/organizer_stats_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../../helpers/fixtures.dart';

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting(AppDateFormats.locale);
  });

  testWidgets('leads with the global fill rate and offers a table view', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(720, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    final stats = OrganizerStats.compute(
      events: [Fixtures.event(availablePlaces: 50)],
      reservations: [Fixtures.reservation()],
      now: Fixtures.now,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(AppConfig.fromFlavor(Flavor.dev)),
          clockProvider.overrideWithValue(() => Fixtures.now),
          organizerStatsProvider.overrideWithValue(AsyncData(stats)),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const OrganizerStatsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Le pourcentage est composé avec une espace insécable avant le « % ».
    expect(find.textContaining(RegExp(r'^50\s%$')), findsWidgets);

    await tester.scrollUntilVisible(
      find.text('Tableau'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Tableau'));
    await tester.pumpAndSettle();

    expect(
      find.text('Une ligne par jour, du plus récent au plus ancien'),
      findsOneWidget,
    );
    expect(find.text('Graphique'), findsOneWidget);
  });
}
