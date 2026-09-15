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

  test(
    'a seat released or a new event from a followed organizer opens the event',
    () {
      for (final type in ['waitlist', 'newEvent']) {
        expect(
          NotificationRoute.locationFor({
            'type': type,
            'eventId': 'evt-1',
            'reservationId': '',
          }),
          AppRoutes.eventDetailPath('evt-1'),
          reason: type,
        );
      }
      expect(NotificationRoute.locationFor({'type': 'newEvent'}), isNull);
    },
  );

  test('moderation notices open the event or the tickets', () {
    expect(
      NotificationRoute.locationFor({'type': 'reviewHidden', 'eventId': 'e1'}),
      AppRoutes.eventDetailPath('e1'),
    );
    expect(
      NotificationRoute.locationFor({'type': 'eventRemoved', 'eventId': 'e1'}),
      AppRoutes.reservations,
    );
  });

  test('team notices open the invitations, the team or the dashboard', () {
    expect(
      NotificationRoute.locationFor({'type': 'staffInvite', 'eventId': 'e1'}),
      AppRoutes.organizerInvitations,
    );
    expect(
      NotificationRoute.locationFor({'type': 'staffJoined', 'eventId': 'e1'}),
      AppRoutes.organizerEventTeamPath('e1'),
    );
    expect(
      NotificationRoute.locationFor({'type': 'staffRemoved', 'eventId': 'e1'}),
      AppRoutes.organizerEvents,
    );
  });

  test('payment notices open the ticket or the tickets list', () {
    expect(
      NotificationRoute.locationFor({
        'type': 'paymentConfirmed',
        'eventId': 'e1',
        'reservationId': 'e1_u1',
      }),
      AppRoutes.ticketPath('e1_u1'),
    );
    expect(
      NotificationRoute.locationFor({
        'type': 'paymentRefunded',
        'eventId': 'e1',
      }),
      AppRoutes.reservations,
    );
  });

  test('reads the data map sent by the worker (uuids, empty when absent)', () {
    const eventId = '6f1c2b0e-8a4d-4c7e-9b1a-2d3e4f5a6b7c';
    const reservationId = 'a2b3c4d5-e6f7-4801-9a2b-3c4d5e6f7a8b';
    expect(
      NotificationRoute.locationFor({
        'type': 'paymentConfirmed',
        'notificationId': '0b9d2c1e-1111-4222-8333-444455556666',
        'eventId': eventId,
        'reservationId': reservationId,
      }),
      AppRoutes.ticketPath(reservationId),
    );
    expect(
      NotificationRoute.locationFor({
        'type': 'booking',
        'notificationId': '0b9d2c1e-1111-4222-8333-444455556666',
        'eventId': '',
        'reservationId': '',
      }),
      isNull,
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
