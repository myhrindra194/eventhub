import '../entities/event.dart';
import '../repositories/event_repository.dart';

class CreateEventUseCase {
  final EventRepository repository;

  CreateEventUseCase(this.repository);

  Future<Event> call(Event event) {
    return repository.createEvent(event);
  }
}
