import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:eventhub/features/notifications/data/device_id_store.dart';
import 'package:eventhub/features/notifications/data/notification_dto.dart';
import 'package:eventhub/features/notifications/domain/notification_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('NotificationPreferences', () {
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

    test('writes exactly the three keys the rules accept', () {
      expect(const NotificationPreferences().toMap().keys.toSet(), {
        'eventReminders',
        'bookingAlerts',
        'followedOrganizers',
      });
    });
  });

  group('NotificationDto', () {
    test('reads a notice document, id apart', () {
      final notification = NotificationDto.fromJson({
        'type': 'booking',
        'title': 'Nouvelle réservation',
        'body': 'Soa a réservé une place.',
        'eventId': 'evt-1',
        'reservationId': 'evt-1_user-1',
        'createdAt': Timestamp.fromDate(DateTime(2026, 9, 14, 8)),
        'readAt': null,
        'expiresAt': Timestamp.fromDate(DateTime(2026, 10, 14, 8)),
      }).toDomain('n1');

      expect(notification.id, 'n1');
      expect(notification.createdAt, DateTime(2026, 9, 14, 8));
      expect(notification.isRead, isFalse);
      expect(notification.routeData, {
        'type': 'booking',
        'eventId': 'evt-1',
        'reservationId': 'evt-1_user-1',
      });
    });

    test('a pending server timestamp still renders, dated now', () {
      final before = DateTime.now();
      final notification = NotificationDto.fromJson({
        'type': 'welcome',
        'title': 'Bienvenue',
        'body': 'Bon événement.',
      }).toDomain('welcome');
      expect(
        notification.createdAt.isBefore(
          before.subtract(const Duration(seconds: 1)),
        ),
        isFalse,
      );
    });

    test('a read notice carries its date', () {
      final notification = NotificationDto.fromJson({
        'type': 'reminder',
        'title': 'Demain',
        'body': 'Rendez-vous à 18:30.',
        'createdAt': Timestamp.fromDate(DateTime(2026, 9, 13)),
        'readAt': Timestamp.fromDate(DateTime(2026, 9, 14)),
      }).toDomain('n2');
      expect(notification.isRead, isTrue);
      expect(notification.readAt, DateTime(2026, 9, 14));
    });
  });

  group('DeviceIdStore', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('creates one installation id and keeps it across tokens', () async {
      final first = await DeviceIdStore().read(token: 'token-a:APA91b');
      expect(first, matches(RegExp(r'^[0-9a-f]{32}$')));

      // Un magasin neuf — nouveau lancement de l'application — avec un jeton
      // renouvelé : c'est le même document qui doit revenir.
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
