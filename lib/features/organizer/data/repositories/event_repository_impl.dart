import 'dart:typed_data';

import '../../domain/entities/event.dart';
import '../../domain/repositories/event_repository.dart';
import '../datasources/event_image_storage_datasource.dart';
import '../datasources/event_remote_datasource.dart';

class EventRepositoryImpl implements EventRepository {
  final EventRemoteDataSource dataSource;
  final EventImageStorageDataSource imageStorage;

  EventRepositoryImpl(this.dataSource, this.imageStorage);

  @override
  Future<List<Event>> getEvents() async {
    return dataSource.getEvents();
  }

  @override
  Future<Event?> getEventById(String id) async {
    return dataSource.getEventById(id);
  }

  @override
  Future<Event> createEvent(
    Event event, {
    Uint8List? imageBytes,
    String? imageExtension,
  }) async {
    return dataSource.createEvent(
      event,
      imageBytes: imageBytes,
      imageExtension: imageExtension,
      imageStorage: imageStorage,
    );
  }

  @override
  Future<Event> updateEvent(Event event) async {
    return dataSource.updateEvent(event);
  }

  @override
  Future<void> deleteEvent(String id) async {
    return dataSource.deleteEvent(id);
  }

  @override
  Future<void> publishEvent(String id) async {
    await dataSource.publishEvent(id);
  }

  @override
  Future<List<Map<String, dynamic>>> getEventParticipants(
    String eventId,
  ) async {
    return dataSource.getEventParticipants(eventId);
  }
}
