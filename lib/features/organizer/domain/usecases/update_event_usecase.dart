import '../entities/event.dart';
import '../repositories/event_repository.dart';

class UpdateEventUseCase {
  final EventRepository repository;

  UpdateEventUseCase(this.repository);

  Future<Event> call(Event event) => repository.updateEvent(event);
}
