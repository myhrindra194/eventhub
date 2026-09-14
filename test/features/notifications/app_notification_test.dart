import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventhub/features/notifications/application/notification_route.dart';
import 'package:eventhub/features/notifications/data/notification_remote_data_source.dart';
import 'package:eventhub/routes/app_routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final created = DateTime(2026, 9, 14, 10, 30);

  test('parses a document written by the Cloud Functions', () {
    final n = NotificationRemoteDataSource.notificationFromFirestore('n1', {
      'type': 'reminder',
      'title': 'Demain : Flutter Meetup',
      'body': 'Rendez-vous à 18:30',
      'eventId': 'e1',
      'reservationId': 'e1_u1',
      'createdAt': Timestamp.fromDate(created),
      'readAt': null,
      'expiresAt': Timestamp.fromDate(created.add(const Duration(days: 30))),
    });

    expect(n.id, 'n1');
    expect(n.createdAt, created);
    expect(n.isRead, isFalse);
    expect(
      NotificationRoute.locationFor(n.routeData),
      AppRoutes.ticketPath('e1_u1'),
    );
  });

  test('tolerates missing and malformed fields', () {
    final n = NotificationRemoteDataSource.notificationFromFirestore('n2', {
      'title': 42,
      'readAt': Timestamp.fromDate(created),
    });
    expect(n.type, 'unknown');
    expect(n.title, '');
    expect(n.isRead, isTrue);
    expect(NotificationRoute.locationFor(n.routeData), isNull);
  });

  test('a waitlist notification opens the event', () {
    expect(
      NotificationRoute.locationFor({'type': 'waitlist', 'eventId': 'e1'}),
      AppRoutes.eventDetailPath('e1'),
    );
  });
}
