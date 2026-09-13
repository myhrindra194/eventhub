import 'package:flutter_test/flutter_test.dart';

import 'package:eventhub/features/events/data/datasources/event_remote_datasource.dart';
import 'package:eventhub/features/events/data/models/event_model.dart';
import 'package:eventhub/features/events/data/repositories/event_repository_impl.dart';
import 'package:eventhub/features/events/domain/entities/event.dart';

import 'event_fixtures.dart';

void main() {
  late FakeEventRemoteDataSource dataSource;
  late EventRepositoryImpl repository;

  setUp(() {
    dataSource = FakeEventRemoteDataSource();
    repository = EventRepositoryImpl(dataSource);
  });

  test('getEvents sans filtre renvoie tous les événements publiés', () async {
    dataSource.models = [
      buildEvent(),
      buildEvent(id: 'event-2', category: 'concert'),
    ];

    final events = await repository.getEvents();

    expect(events.length, 2);
  });

  test('getEvents filtre par catégorie en ignorant la casse', () async {
    dataSource.models = [
      buildEvent(category: 'concert'),
      buildEvent(id: 'event-2', category: 'conference'),
      buildEvent(id: 'event-3', category: 'workshop'),
    ];

    final concerts = await repository.getEvents(category: 'CONCERT');

    expect(concerts.length, 1);
    expect(concerts.single.category, EventCategory.concert);
  });

  test('getEvents avec "All" ou null ne filtre pas', () async {
    dataSource.models = [
      buildEvent(),
      buildEvent(id: 'event-2', category: 'sport'),
    ];

    final all = await repository.getEvents(category: '  all  ');

    expect(all.length, 2);
  });

  test(
    'getEvents avec une catégorie inconnue renvoie une liste vide',
    () async {
      dataSource.models = [buildEvent()];

      final empty = await repository.getEvents(category: 'history');

      expect(empty, isEmpty);
    },
  );

  test('getEventById retourne null si absent', () async {
    final event = await repository.getEventById('unknown');

    expect(event, isNull);
  });

  test('searchEvents cherche aussi dans la localisation', () async {
    dataSource.models = [
      buildEvent(title: 'Concert Lyon', location: 'Lyon'),
      buildEvent(id: 'event-2', title: 'Hackathon', location: 'Paris'),
    ];

    final byLocation = await repository.searchEvents('paris');

    expect(byLocation.map((e) => e.id), ['event-2']);
  });

  test('watchEvents applique le filtre catégorie à chaque émission', () async {
    dataSource.models = [
      buildEvent(category: 'concert'),
      buildEvent(id: 'event-2', category: 'conference'),
    ];

    final first = await repository.watchEvents(category: 'conference').first;

    expect(first.length, 1);
    expect(first.single.category, EventCategory.conference);
  });
}

/// Fake fait main : évite le couplage à mocktail pour une classe concrète
/// (pattern identique à `auth_architecture_test.dart`).
class FakeEventRemoteDataSource implements EventRemoteDataSource {
  List<EventModel> models = [];
  EventModel? eventById;

  @override
  Future<List<EventModel>> getPublishedEvents() async => models;

  @override
  Stream<List<EventModel>> watchPublishedEvents() => Stream.value(models);

  @override
  Future<EventModel?> getEventById(String id) async => eventById;
}
