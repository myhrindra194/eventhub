import '../entities/event.dart';
import '../repositories/event_repository.dart';

class GetEventDetailUseCase {
  final EventRepository repository;

  GetEventDetailUseCase(this.repository);

  Future<Event?> call(String id) {
    return repository.getEventById(id);
  }
}
