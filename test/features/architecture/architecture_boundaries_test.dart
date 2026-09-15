import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eventhub/core/router/app_router.dart';
import 'package:eventhub/features/events/data/models/event_model.dart';
import 'package:eventhub/features/events/domain/entities/event.dart';
import 'package:eventhub/features/reservations/data/models/reservation_model.dart';
import 'package:eventhub/features/reservations/domain/usecases/create_reservation_usecase.dart';

void main() {
  test('event data models map to independent domain entities', () {
    final model = EventModel(
      id: 'event-1',
      title: 'Conference',
      description: 'Description',
      date: DateTime(2026, 10, 15, 10),
      location: 'Paris',
      imageUrl: 'assets/images/tech.jpg',
      category: 'conference',
      status: 'live',
      price: 12.5,
      capacity: 100,
      currentAttendees: 80,
      organizerId: 'organizer-1',
    );

    final entity = model.toEntity();

    expect(entity.title, 'Conference');
    expect(entity.price, 12.5);
    expect(entity.category, EventCategory.conference);
    expect(entity.status, EventStatus.live);
    expect(entity.availablePlaces, 20);
    expect(entity, isNot(isA<EventModel>()));
  });

  test('event model tolerates numeric capacity sent as double', () {
    // Régression : Firestore renvoie parfois un double pour un champ int.
    final model = EventModel.fromJson({
      'id': 'event-1',
      'title': 'Conference',
      'description': 'Description',
      'date': DateTime(2026, 10, 15, 10),
      'location': 'Paris',
      'imageUrl': 'assets/images/tech.jpg',
      'category': 'concert',
      'status': 'LIVE',
      'capacity': 100.0,
      'currentAttendees': 80.0,
    });

    expect(model.capacity, 100);
    expect(model.currentAttendees, 80);
    final entity = model.toEntity();
    expect(entity.category, EventCategory.concert);
    expect(entity.status, EventStatus.live);
  });

  test('reservation data models map to domain entities', () {
    const model = ReservationModel(
      id: 'reservation-1',
      eventId: 'event-1',
      eventTitle: 'Conference',
      date: '15 OCT',
      status: 'confirmed',
      seatInfo: '2 x GENERAL ACCESS',
      quantity: 2,
    );

    final entity = model.toEntity();

    expect(entity.eventId, 'event-1');
    expect(entity.status, 'confirmed');
    expect(entity.quantity, 2);
    expect(entity, isNot(isA<ReservationModel>()));
  });

  test('create reservation use case validates requested quantity', () {
    final event = Event(
      id: 'event-1',
      title: 'Conference',
      description: 'Description',
      imageUrl: 'assets/images/tech.jpg',
      date: DateTime(2026, 10, 15, 10),
      capacity: 100,
      currentAttendees: 98,
      status: EventStatus.live,
      location: 'Paris',
      price: 0,
    );

    final useCase = CreateReservationUseCase();
    final reservation = useCase(event: event, quantity: 2);

    expect(reservation.seatInfo, '2 x GENERAL ACCESS');
    expect(reservation.eventId, 'event-1');
    expect(() => useCase(event: event, quantity: 3), throwsStateError);
  });

  test('router accepts event detail and confirmation arguments', () {
    final event = Event(
      id: 'event-1',
      title: 'Conference',
      description: 'Description',
      imageUrl: 'assets/images/tech.jpg',
      date: DateTime(2026, 10, 15, 10),
      capacity: 100,
      currentAttendees: 0,
      status: EventStatus.live,
      location: 'Paris',
      price: 0,
    );

    final detailRoute = AppRouter.generateRoute(
      const RouteSettings(name: AppRouter.eventDetail, arguments: 'event-1'),
    );
    final confirmationRoute = AppRouter.generateRoute(
      RouteSettings(name: AppRouter.reservationConfirmation, arguments: event),
    );

    expect(detailRoute, isA<MaterialPageRoute>());
    expect(confirmationRoute, isA<MaterialPageRoute>());
  });
}
