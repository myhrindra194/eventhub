import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/config/app_config.dart';
import 'package:eventhub/core/config/flavor.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/utils/date_formats.dart';
import 'package:eventhub/features/admin/application/moderation_providers.dart';
import 'package:eventhub/features/admin/domain/moderation.dart';
import 'package:eventhub/features/admin/presentation/screens/moderation_queue_screen.dart';
import 'package:eventhub/features/moderation/domain/report.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting(AppDateFormats.locale);
  });

  final open = [
    ModerationEntry(
      id: 'review_e1_p9',
      target: ReportTarget.review,
      targetId: 'e1_p9',
      reportCount: 3,
      status: ModerationStatus.open,
      lastReason: ReportReason.harassment,
      autoHidden: true,
      updatedAt: DateTime(2026, 9, 14, 9),
    ),
    ModerationEntry(
      id: 'event_e2',
      target: ReportTarget.event,
      targetId: 'e2',
      reportCount: 1,
      status: ModerationStatus.open,
      lastReason: ReportReason.fraud,
      updatedAt: DateTime(2026, 9, 14, 8),
    ),
  ];

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(720, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(AppConfig.fromFlavor(Flavor.dev)),
          moderationQueueProvider(
            open: true,
          ).overrideWith((ref) => Stream.value(open)),
          moderationQueueProvider(
            open: false,
          ).overrideWith((ref) => Stream.value(const [])),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const ModerationQueueScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('lists open files with reason, count and the auto-hide mark', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('À traiter · 2'), findsOneWidget);
    expect(find.text('Avis · Harcèlement'), findsOneWidget);
    expect(find.text('Événement · Arnaque'), findsOneWidget);
    // Badges are set in capitals.
    expect(find.text(AppStrings.autoHiddenShort.toUpperCase()), findsOneWidget);
  });

  testWidgets('filters by target type and shows the empty handled tab', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.text(ReportTarget.event.label));
    await tester.pumpAndSettle();
    expect(find.text('Avis · Harcèlement'), findsNothing);
    expect(find.text('Événement · Arnaque'), findsOneWidget);

    await tester.tap(find.text(AppStrings.moderationClosed));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.moderationNothingClosedTitle), findsOneWidget);
  });
}
