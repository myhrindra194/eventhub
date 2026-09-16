import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/config/app_config.dart';
import 'package:eventhub/core/config/flavor.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/utils/date_formats.dart';
import 'package:eventhub/features/notifications/application/notification_providers.dart';
import 'package:eventhub/features/notifications/domain/app_notification.dart';
import 'package:eventhub/features/notifications/presentation/screens/notifications_screen.dart';
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

  final now = DateTime(2026, 9, 14, 12);

  Future<void> pumpFeed(
    WidgetTester tester,
    List<AppNotification> items,
  ) async {
    tester.view.physicalSize = const Size(720, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(AppConfig.fromFlavor(Flavor.dev)),
          clockProvider.overrideWithValue(() => now),
          notificationFeedProvider.overrideWith((ref) => Stream.value(items)),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const NotificationsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('groups entries by day and offers to mark all read', (
    tester,
  ) async {
    await pumpFeed(tester, [
      AppNotification(
        id: 'n1',
        type: 'booking',
        title: 'Nouvelle réservation',
        body: 'Jean Rakoto a réservé une place.',
        eventId: 'e1',
        createdAt: now.subtract(const Duration(hours: 1)),
      ),
      AppNotification(
        id: 'n2',
        type: 'reminder',
        title: 'Demain : Flutter Meetup',
        body: 'Rendez-vous à 18:30.',
        reservationId: 'e1_u1',
        createdAt: now.subtract(const Duration(days: 1)),
        readAt: now,
      ),
    ]);

    expect(find.text("Aujourd'hui"), findsOneWidget);
    expect(find.text('Hier'), findsOneWidget);
    expect(find.text('Nouvelle réservation'), findsOneWidget);
    expect(find.text(AppStrings.markAllRead), findsOneWidget);
  });

  testWidgets('an empty history explains the 30-day retention', (tester) async {
    await pumpFeed(tester, const []);

    expect(find.text(AppStrings.noNotificationsTitle), findsOneWidget);
    expect(find.text(AppStrings.markAllRead), findsNothing);
  });
}
