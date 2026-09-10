import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eventhub/core/router/app_router.dart';
import 'package:eventhub/features/events/data/models/event_model.dart';
import 'package:eventhub/features/reservations/data/models/reservation_model.dart';
import 'package:eventhub/features/reservations/domain/usecases/create_reservation_usecase.dart';

void main() {
  test('event data models map to independent domain entities', () {
    const model = EventModel(
      id: 'event-1',
      title: 'Conference',
      description: 'Description',
      date: '15 OCT',
      month: 'OCT',
      day: '15',
      time: '10:00 AM',
      location: 'Paris',
      imageUrl: 'assets/images/tech.jpg',
      imagePath: 'assets/images/tech.jpg',
      category: 'Tech',
      price: 12.5,
      capacity: 100,
      availablePlaces: 20,
    );

    final entity = model.toEntity();

    expect(entity.title, 'Conference');
    expect(entity.price, 12.5);
    expect(entity, isNot(isA<EventModel>()));
  });

  test('reservation data models map to domain entities', () {
    const model = ReservationModel(
      id: 'reservation-1',
      eventTitle: 'Conference',
      date: '15 OCT',
      status: 'CONFIRMED',
      seatInfo: '2 x GENERAL ACCESS',
    );

    final entity = model.toEntity();

    expect(entity.status, 'CONFIRMED');
    expect(entity, isNot(isA<ReservationModel>()));
  });

  test('create reservation use case validates requested quantity', () {
    const event = EventModel(
      id: 'event-1',
      title: 'Conference',
      description: 'Description',
      date: '15 OCT',
      month: 'OCT',
      day: '15',
      time: '10:00 AM',
      location: 'Paris',
      imageUrl: 'assets/images/tech.jpg',
      imagePath: 'assets/images/tech.jpg',
      category: 'Tech',
      availablePlaces: 2,
    );

    final useCase = CreateReservationUseCase();
    final reservation = useCase(event: event.toEntity(), quantity: 2);

    expect(reservation.seatInfo, '2 x GENERAL ACCESS');
    expect(
      () => useCase(event: event.toEntity(), quantity: 3),
      throwsStateError,
    );
  });

  test('router accepts event detail and confirmation arguments', () {
    final detailRoute = AppRouter.generateRoute(
      const RouteSettings(name: AppRouter.eventDetail, arguments: 'event-1'),
    );
    final confirmationRoute = AppRouter.generateRoute(
      RouteSettings(
        name: AppRouter.reservationConfirmation,
        arguments: const EventModel(
          id: 'event-1',
          title: 'Conference',
          description: 'Description',
          date: '15 OCT',
          month: 'OCT',
          day: '15',
          time: '10:00 AM',
          location: 'Paris',
          imageUrl: 'assets/images/tech.jpg',
          imagePath: 'assets/images/tech.jpg',
          category: 'Tech',
        ).toEntity(),
      ),
    );

    expect(detailRoute, isA<MaterialPageRoute>());
    expect(confirmationRoute, isA<MaterialPageRoute>());
  });
}
