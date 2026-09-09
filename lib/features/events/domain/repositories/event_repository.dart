import '../entities/event.dart';

abstract class EventRepository {
  Future<List<Event>> getEvents({String? category});
}