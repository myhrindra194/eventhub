import '../entities/event.dart';

abstract class EventRepository {
  Future<List<Event>> getEvents();
  Future<Event?> getEventById(String id);
  Future<Event> createEvent(Event event);
  Future<Event> updateEvent(Event event);
  Future<void> deleteEvent(String id);
  Future<void> publishEvent(String id);
  Future<List<Map<String, dynamic>>> getEventParticipants(String eventId);
}
