import 'dart:typed_data';

import '../../../events/domain/entities/event.dart';

abstract class EventRepository {
  Future<List<Event>> getEvents();

  Future<Event?> getEventById(String id);

  Stream<List<Event>> watchEvents();

  Future<Event> createEvent(
    Event event, {
    Uint8List? imageBytes,
    String? imageExtension,
  });

  Future<Event> updateEvent(Event event);

  Future<void> deleteEvent(String id);

  Future<void> publishEvent(String id);

  Future<List<Map<String, dynamic>>> getEventParticipants(String eventId);
}
