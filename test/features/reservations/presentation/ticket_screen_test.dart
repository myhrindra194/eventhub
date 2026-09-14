import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/config/app_config.dart';
import 'package:eventhub/core/config/flavor.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/utils/date_formats.dart';
import 'package:eventhub/features/reservations/application/reservation_providers.dart';
import 'package:eventhub/features/reservations/domain/entities/reservation.dart';
import 'package:eventhub/features/reservations/presentation/screens/ticket_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../helpers/fixtures.dart';

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting(AppDateFormats.locale);
  });

  Future<void> pumpTicket(WidgetTester tester, Reservation reservation) async {
    tester.view.physicalSize = const Size(720, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(AppConfig.fromFlavor(Flavor.dev)),
          clockProvider.overrideWithValue(() => Fixtures.now),
          reservationByIdProvider(
            reservation.id,
          ).overrideWith((ref) => Stream.value(reservation)),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: TicketScreen(reservationId: reservation.id),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a valid ticket shows its QR code and short code', (
    tester,
  ) async {
    final reservation = Fixtures.reservation();
    await pumpTicket(tester, reservation);

    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text(reservation.ticketCode), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text(AppStrings.ticketEntrance),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text(AppStrings.ticketEntrance), findsOneWidget);
  });

  testWidgets('a cancelled ticket says it no longer admits', (tester) async {
    await pumpTicket(
      tester,
      Fixtures.reservation(status: ReservationStatus.cancelled),
    );

    await tester.scrollUntilVisible(
      find.text(AppStrings.ticketCancelledNotice),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text(AppStrings.ticketCancelledNotice), findsOneWidget);
  });
}
