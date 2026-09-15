import 'package:eventhub/features/notifications/data/device_id_store.dart';
import 'package:eventhub/features/notifications/data/notification_dto.dart';
import 'package:eventhub/features/notifications/domain/notification_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  });

  group('NotificationPreferencesDto', () {
    test('reads the row of public.notification_preferences', () {
      final prefs = NotificationPreferencesDto.fromJson({
        'user_id': 'f0e1d2c3-b4a5-4697-8879-6a5b4c3d2e1f',
        'event_reminders': false,
        'booking_alerts': true,
        'followed_organizers': false,
        'updated_at': '2026-09-14T08:30:00+00:00',
      }).toDomain();
      expect(
        prefs,
        const NotificationPreferences(
          eventReminders: false,
          followedOrganizers: false,
        ),
      );
    });

    test('writes exactly the three columns granted for update', () {
      final json = NotificationPreferencesDto.fromDomain(
        const NotificationPreferences(bookingAlerts: false),
      ).toJson();
      expect(json, {
        'event_reminders': true,
        'booking_alerts': false,
        'followed_organizers': true,
      });
    });
  });

  group('DeviceIdStore', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('creates one installation id and keeps it across tokens', () async {
      final first = await DeviceIdStore().read(token: 'token-a:APA91b');
      expect(first, matches(RegExp(r'^[0-9a-f]{32}$')));

      // A fresh store (new app launch) with a rotated token: same row.
      final again = await DeviceIdStore().read(token: 'token-b:APA91b');
      expect(again, first);
    });

    test('falls back to a token-derived id without local storage', () async {
      final store = DeviceIdStore(
        preferences: () => Future.error(StateError('no storage')),
      );
      final id = await store.read(token: 'token-a:APA91b');
      expect(id, DeviceIdStore.deviceIdFor('token-a:APA91b'));
    });

    test('the fallback is stable, 16 hex characters, distinct per token', () {
      final a = DeviceIdStore.deviceIdFor('token-a:APA91b');
      expect(a, matches(RegExp(r'^[0-9a-f]{16}$')));
      expect(DeviceIdStore.deviceIdFor('token-a:APA91b'), a);
      expect(DeviceIdStore.deviceIdFor('token-b:APA91b'), isNot(a));
    });
  });
}
