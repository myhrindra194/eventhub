import '../entities/event.dart';
import '../repositories/event_repository.dart';

class SearchEventsUseCase {
  final EventRepository repository;

  SearchEventsUseCase(this.repository);

  Future<List<Event>> call(String query) async {
    if (query.isEmpty) {
      return repository.getEvents();
    }
    return repository.searchEvents(query);
  }
}
