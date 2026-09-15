import 'package:eventhub/features/notifications/application/notification_route.dart';
import 'package:eventhub/features/notifications/data/notification_dto.dart';
import 'package:eventhub/features/notifications/data/notification_remote_data_source.dart';
import 'package:eventhub/routes/app_routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const eventId = '6f1c2b0e-8a4d-4c7e-9b1a-2d3e4f5a6b7c';
  const reservationId = 'a2b3c4d5-e6f7-4801-9a2b-3c4d5e6f7a8b';
  final created = DateTime.utc(2026, 9, 14, 8, 30);

  Map<String, dynamic> row({
    String id = '0b9d2c1e-1111-4222-8333-444455556666',
    String type = 'reminder',
    Object? createdAt,
    Object? readAt,
    Object? expiresAt,
    String? event = eventId,
    String? reservation = reservationId,
  }) => {
    'id': id,
    'user_id': 'f0e1d2c3-b4a5-4697-8879-6a5b4c3d2e1f',
    'type': type,
    'title': 'Demain : Flutter Meetup',
    'body': 'Rendez-vous à 18:30',
    'event_id': event,
    'reservation_id': reservation,
    'created_at': createdAt ?? created.toIso8601String(),
    'read_at': readAt,
    'expires_at':
        expiresAt ?? created.add(const Duration(days: 30)).toIso8601String(),
  };

  group('NotificationDto', () {
    test('parses a PostgREST / Realtime row with snake_case keys', () {
      final n = NotificationDto.fromJson(row()).toDomain();

      expect(n.id, '0b9d2c1e-1111-4222-8333-444455556666');
      expect(n.type, 'reminder');
      expect(n.createdAt.isAtSameMomentAs(created), isTrue);
      expect(n.createdAt.isUtc, isFalse, reason: 'shown in local time');
      expect(n.eventId, eventId);
      expect(n.reservationId, reservationId);
      expect(n.isRead, isFalse);
      expect(
        NotificationRoute.locationFor(n.routeData),
        AppRoutes.ticketPath(reservationId),
      );
    });

    test('a read row with no event or reservation routes nothing', () {
      final n = NotificationDto.fromJson(
        row(
          type: 'booking',
          readAt: '2026-09-14T09:00:00+00:00',
          event: null,
          reservation: null,
        ),
      ).toDomain();
      expect(n.isRead, isTrue);
      expect(NotificationRoute.locationFor(n.routeData), isNull);
    });

    test('keeps a type the app does not know yet', () {
      final n = NotificationDto.fromJson(row(type: 'promo')).toDomain();
      expect(n.type, 'promo');
      expect(NotificationRoute.locationFor(n.routeData), isNull);
    });
  });

  group('notificationsFromRows', () {
    final now = created.add(const Duration(days: 1));

    test('sorts most recent first and skips malformed rows', () {
      final list = NotificationRemoteDataSource.notificationsFromRows([
        row(id: 'old', createdAt: '2026-09-13T08:00:00Z'),
        {'id': 'broken', 'title': 42},
        row(id: 'new', createdAt: '2026-09-14T10:00:00Z'),
      ], now: now);
      expect(list.map((n) => n.id), ['new', 'old']);
    });

    test('hides rows past their expiry while the purge has not run', () {
      final list = NotificationRemoteDataSource.notificationsFromRows([
        row(id: 'expired', expiresAt: '2026-09-14T12:00:00Z'),
        row(id: 'live'),
      ], now: now);
      expect(list.map((n) => n.id), ['live']);
    });

    test('is bounded', () {
      final rows = [
        for (var i = 0; i < 150; i++)
          row(
            id: 'n$i',
            createdAt: created.add(Duration(minutes: i)).toIso8601String(),
          ),
      ];
      final list = NotificationRemoteDataSource.notificationsFromRows(
        rows,
        now: now,
      );
      expect(list, hasLength(NotificationRemoteDataSource.maxNotifications));
      expect(list.first.id, 'n149');
    });
  });
}
