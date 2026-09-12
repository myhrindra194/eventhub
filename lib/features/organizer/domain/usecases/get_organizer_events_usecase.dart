import '../entities/event.dart';
import '../repositories/event_repository.dart';

class GetOrganizerEventsUseCase {
  final EventRepository repository;

  GetOrganizerEventsUseCase(this.repository);

  Future<List<Event>> call() => repository.getEvents();
}
