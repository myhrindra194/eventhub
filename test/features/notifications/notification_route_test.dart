import 'package:eventhub/features/notifications/application/notification_route.dart';
import 'package:eventhub/routes/app_routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('booking and cancellation open the event guest list', () {
    for (final type in ['booking', 'cancellation']) {
      expect(
        NotificationRoute.locationFor({'type': type, 'eventId': 'evt-1'}),
        AppRoutes.organizerEventParticipantsPath('evt-1'),
      );
    }
  });

  test('a reminder opens the ticket', () {
    expect(
      NotificationRoute.locationFor({
        'type': 'reminder',
        'eventId': 'evt-1',
        'reservationId': 'evt-1_u1',
      }),
      AppRoutes.ticketPath('evt-1_u1'),
    );
  });

  test('unknown or incomplete payloads open nothing', () {
    expect(NotificationRoute.locationFor({}), isNull);
    expect(NotificationRoute.locationFor({'type': 'promo'}), isNull);
    expect(NotificationRoute.locationFor({'type': 'booking'}), isNull);
    expect(
      NotificationRoute.locationFor({'type': 'reminder', 'reservationId': ''}),
      isNull,
    );
  });
}
