import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:eventhub/features/notifications/application/notification_route.dart';
import 'package:eventhub/features/notifications/data/notification_dto.dart';
import 'package:eventhub/features/notifications/data/notification_remote_data_source.dart';
import 'package:eventhub/routes/app_routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const eventId = 'evt-1';
  const reservationId = 'evt-1_user-1';
  final created = DateTime(2026, 9, 14, 8, 30);

  Map<String, dynamic> notice({
    String type = 'reminder',
    Object? createdAt,
    Object? readAt,
    Object? expiresAt,
    String? event = eventId,
    String? reservation = reservationId,
  }) => {
    'type': type,
    'title': 'Demain : Flutter Meetup',
    'body': 'Rendez-vous à 18:30',
    'eventId': event,
    'reservationId': reservation,
    'actorId': 'user-1',
    'createdAt': createdAt ?? Timestamp.fromDate(created),
    'readAt': readAt,
    'expiresAt':
        expiresAt ?? Timestamp.fromDate(created.add(const Duration(days: 30))),
  };

  group('NotificationDto', () {
    test('parses a notice document, its id coming from the snapshot', () {
      final n = NotificationDto.fromJson(notice()).toDomain('n1');

      expect(n.id, 'n1');
      expect(n.type, 'reminder');
      expect(n.createdAt, created);
      expect(n.eventId, eventId);
      expect(n.reservationId, reservationId);
      expect(n.isRead, isFalse);
      expect(
        NotificationRoute.locationFor(n.routeData),
        AppRoutes.ticketPath(reservationId),
      );
    });

    test('a read notice with no event or reservation routes nothing', () {
      final n = NotificationDto.fromJson(
        notice(
          type: 'booking',
          readAt: Timestamp.fromDate(created.add(const Duration(hours: 1))),
          event: null,
          reservation: null,
        ),
      ).toDomain('n2');
      expect(n.isRead, isTrue);
      expect(NotificationRoute.locationFor(n.routeData), isNull);
    });

    test('keeps a type this build does not know yet', () {
      final n = NotificationDto.fromJson(notice(type: 'promo')).toDomain('n3');
      expect(n.type, 'promo');
      expect(NotificationRoute.locationFor(n.routeData), isNull);
    });

    test('a moderation notice opens the event it is about', () {
      final n = NotificationDto.fromJson(
        notice(type: 'reviewRestored', reservation: null),
      ).toDomain('n4');
      expect(
        NotificationRoute.locationFor(n.routeData),
        AppRoutes.eventDetailPath(eventId),
      );
    });
  });

  group('notificationsFrom', () {
    final now = created.add(const Duration(days: 1));

    test('keeps the order of the snapshot, most recent first by query', () {
      final list = NotificationRemoteDataSource.notificationsFrom([
        ('new', notice(createdAt: Timestamp.fromDate(now))),
        ('old', notice(createdAt: Timestamp.fromDate(created))),
      ], now: now);
      expect(list.map((n) => n.id), ['new', 'old']);
    });

    test('skips a malformed document instead of emptying the screen', () {
      final list = NotificationRemoteDataSource.notificationsFrom([
        // `title` n'est pas une chaîne : `fromJson` lève sur ce document-là,
        // et sur lui seul.
        ('broken', {'type': 'booking', 'title': 42}),
        ('live', notice()),
      ], now: now);
      expect(list.map((n) => n.id), ['live']);
    });

    test('hides a notice past its expiry while the TTL has not swept', () {
      final list = NotificationRemoteDataSource.notificationsFrom([
        (
          'expired',
          notice(
            expiresAt: Timestamp.fromDate(
              now.subtract(const Duration(hours: 1)),
            ),
          ),
        ),
        ('live', notice()),
      ], now: now);
      expect(list.map((n) => n.id), ['live']);
    });

    test('a notice without expiry is kept', () {
      // Les règles exigent `expiresAt`, mais un document plus ancien ou écrit
      // à la main peut en être dépourvu : on l'affiche alors, plutôt que de
      // l'écarter en silence.
      final undated = {...notice()}..remove('expiresAt');
      final list = NotificationRemoteDataSource.notificationsFrom([
        ('n1', undated),
      ], now: now);
      expect(list, hasLength(1));
    });
  });
}
