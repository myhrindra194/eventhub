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
