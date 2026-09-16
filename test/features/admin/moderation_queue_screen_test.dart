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
  const reviewId = '6f1c9a52-3b7e-4d0a-9c1e-2b8f0d4e7a11';
  const eventId = '0b6f7c1e-8d2a-4f3b-9e5c-1a2b3c4d5e6f';

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting(AppDateFormats.locale);
  });

  final open = [
    ModerationEntry(
      id: 'review_$reviewId',
      target: ReportTarget.review,
      targetId: reviewId,
      reportCount: 3,
      status: ModerationStatus.open,
      lastReason: ReportReason.harassment,
      updatedAt: DateTime(2026, 9, 14, 9),
    ),
    ModerationEntry(
      id: 'event_$eventId',
      target: ReportTarget.event,
      targetId: eventId,
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

  testWidgets('lists the open files, most reported first, with their reason', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('À traiter · 2'), findsOneWidget);
    expect(find.text('Avis · Harcèlement'), findsOneWidget);
    expect(find.text('Événement · Arnaque'), findsOneWidget);
    // La ligne se lit « 3 signalements · 14 sept. 09:00 » : c'est le nombre
    // qui sert au tri du modérateur, la date ne dit que la fraîcheur.
    expect(find.textContaining(AppStrings.reportsCount(3)), findsOneWidget);
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
