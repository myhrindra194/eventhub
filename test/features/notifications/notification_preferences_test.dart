import 'package:eventhub/features/notifications/data/notification_remote_data_source.dart';
import 'package:eventhub/features/notifications/domain/notification_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationPreferences.fromMap', () {
    test('defaults every switch to on when the document is missing', () {
      expect(
        NotificationPreferences.fromMap(null),
        const NotificationPreferences(),
      );
    });

    test('reads stored booleans and ignores malformed values', () {
      final prefs = NotificationPreferences.fromMap({
        'eventReminders': false,
        'bookingAlerts': 'nope',
      });
      expect(prefs.eventReminders, isFalse);
      expect(prefs.bookingAlerts, isTrue);
    });

    test('round-trips through toMap', () {
      const prefs = NotificationPreferences(
        eventReminders: false,
        bookingAlerts: false,
        followedOrganizers: false,
      );
      expect(NotificationPreferences.fromMap(prefs.toMap()), prefs);
    });

    test(
      'keeps followed-organizer pushes on for documents written before the switch existed',
      () {
        final prefs = NotificationPreferences.fromMap({
          'eventReminders': false,
          'bookingAlerts': true,
        });
        expect(prefs.followedOrganizers, isTrue);
        expect(
          prefs
              .copyWith(followedOrganizers: false)
              .toMap()['followedOrganizers'],
          isFalse,
        );
      },
    );
  });

  group('deviceIdFor', () {
    test('is stable, 16 hex characters, distinct per token', () {
      final a = NotificationRemoteDataSource.deviceIdFor('token-a:APA91b');
      expect(a, matches(RegExp(r'^[0-9a-f]{16}$')));
      expect(NotificationRemoteDataSource.deviceIdFor('token-a:APA91b'), a);
      expect(
        NotificationRemoteDataSource.deviceIdFor('token-b:APA91b'),
        isNot(a),
      );
    });
  });
}
