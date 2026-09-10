import '../entities/event.dart';

abstract class EventRepository {
  Future<List<Event>> getEvents({String? category});
  Future<List<Event>> searchEvents(String query);
}
