import '../entities/event.dart';

abstract class EventRepository {
  Future<List<Event>> getEvents({String? category});

  /// Stream temps réel des événements publiés (mise à jour sans invalidate).
  Stream<List<Event>> watchEvents({String? category});

  Future<List<Event>> searchEvents(String query);
  Future<Event?> getEventById(String id);
}
