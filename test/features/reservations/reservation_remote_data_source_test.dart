import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eventhub/features/reservations/data/datasources/reservation_remote_data_source.dart';
import 'package:eventhub/features/reservations/data/models/reservation_model.dart';

import '../../helpers/firebase_auth_fixtures.dart';

/// Fixture : une réservation valide pour 2 places.
ReservationModel _reservation({
  String eventId = 'event-1',
  int quantity = 2,
}) {
  return ReservationModel(
    id: '',
    eventId: eventId,
    eventTitle: 'Tech Meetup',
    date: '20/11/2026 • 18:00',
    status: 'confirmed',
    seatInfo: '2 x GENERAL ACCESS',
    quantity: quantity,
  );
}

Future<void> _seedEvent(
  FakeFirebaseFirestore firestore, {
  int capacity = 100,
  int currentAttendees = 0,
  String id = 'event-1',
}) async {
  await firestore.collection('events').doc(id).set({
    'title': 'Tech Meetup',
    'description': 'D',
    'status': 'live',
    'capacity': capacity,
    'currentAttendees': currentAttendees,
    'organizerId': 'org-1',
    'price': 0,
  });
}

void main() {
  late FakeFirebaseFirestore firestore;
  late ReservationRemoteDataSourceImpl dataSource;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    dataSource = ReservationRemoteDataSourceImpl(
      firestore: firestore,
      firebaseAuth: buildMockFirebaseAuth(),
    );
  });

  test(
    'saveReservation incrémente currentAttendees et crée la réservation',
    () async {
      await _seedEvent(firestore, capacity: 100, currentAttendees: 20);

      await dataSource.saveReservation(_reservation());

      final event = await firestore.collection('events').doc('event-1').get();
      expect(event.get('currentAttendees'), 22);

      final reservations = await firestore.collection('reservations').get();
      expect(reservations.docs.length, 1);
      final saved = reservations.docs.first.data();
      expect(saved['userId'], 'user-1');
      expect(saved['eventId'], 'event-1');
      expect(saved['status'], 'confirmed');
      expect(saved['quantity'], 2);
      expect(saved['reservedAt'], isNotNull);
    },
  );

  test('saveReservation refuse quand la capacité est dépassée', () async {
    await _seedEvent(firestore, capacity: 100, currentAttendees: 99);

    expect(
      () => dataSource.saveReservation(_reservation()),
      throwsA(isA<StateError>()),
    );

    // Aucune réservation ni mise à jour écrites.
    final reservations = await firestore.collection('reservations').get();
    expect(reservations.docs, isEmpty);
  });

  test('saveReservation refuse quand l\'événement n\'existe pas', () async {
    expect(
      () => dataSource.saveReservation(_reservation(eventId: 'missing')),
      throwsA(isA<StateError>()),
    );
  });

  test('saveReservation exige un utilisateur connecté', () async {
    // Auth non signée => currentUser null.
    dataSource = ReservationRemoteDataSourceImpl(
      firestore: firestore,
      firebaseAuth: buildMockFirebaseAuthSignedOut(),
    );

    expect(
      () => dataSource.saveReservation(_reservation()),
      throwsA(isA<StateError>()),
    );
  });

  test(
    'saveReservation utilise un timestamp réel pour reservedAt (pas serverTimestamp)',
    () async {
      await _seedEvent(firestore, capacity: 100, currentAttendees: 0);

      final before = DateTime.now();
      await dataSource.saveReservation(_reservation());
      final after = DateTime.now();

      final reservations = await firestore.collection('reservations').get();
      final saved = reservations.docs.first.data();

      // `reservedAt` doit être un DateTime réel, pas un placeholder
      // `FieldValue.serverTimestamp()`.
      final rawReservedAt = saved['reservedAt'];
      // `fake_cloud_firestore` sérialise DateTime en Timestamp Firestore.
      final reservedAt = rawReservedAt is Timestamp
          ? rawReservedAt.toDate()
          : rawReservedAt as DateTime;
      expect(reservedAt, isA<DateTime>());
      expect(
        reservedAt.isAfter(before.subtract(const Duration(seconds: 2))),
        isTrue,
      );
      expect(
        reservedAt.isBefore(after.add(const Duration(seconds: 2))),
        isTrue,
      );
    },
  );

  test(
    'saveReservation utilise un timestamp réel pour updatedAt sur l\'événement',
    () async {
      await _seedEvent(firestore, capacity: 100, currentAttendees: 10);

      final before = DateTime.now();
      await dataSource.saveReservation(_reservation(quantity: 3));
      final after = DateTime.now();

      final event = await firestore.collection('events').doc('event-1').get();
      final rawUpdatedAt = event.get('updatedAt');

      // `fake_cloud_firestore` sérialise DateTime en Timestamp Firestore.
      final updatedAt = rawUpdatedAt is Timestamp
          ? rawUpdatedAt.toDate()
          : rawUpdatedAt as DateTime;
      expect(updatedAt, isA<DateTime>());
      expect(
        updatedAt.isAfter(before.subtract(const Duration(seconds: 2))),
        isTrue,
      );
      expect(
        updatedAt.isBefore(after.add(const Duration(seconds: 2))),
        isTrue,
      );
    },
  );

  test(
    'fetchUserReservations ne renvoie que les réservations du user',
    () async {
      await firestore.collection('reservations').doc('r1').set({
        'userId': 'user-1',
        'eventId': 'event-1',
        'eventTitle': 'Tech Meetup',
        'status': 'confirmed',
        'quantity': 1,
      });
      await firestore.collection('reservations').doc('r2').set({
        'userId': 'someone-else',
        'eventId': 'event-1',
        'eventTitle': 'Tech Meetup',
        'status': 'confirmed',
        'quantity': 1,
      });

      final reservations = await dataSource.fetchUserReservations();

      expect(reservations.length, 1);
      expect(reservations.single.eventId, 'event-1');
    },
  );

  test('fetchUserReservations renvoie une liste vide sans session', () async {
    dataSource = ReservationRemoteDataSourceImpl(
      firestore: firestore,
      firebaseAuth: buildMockFirebaseAuthSignedOut(),
    );

    final reservations = await dataSource.fetchUserReservations();

    expect(reservations, isEmpty);
  });
}
