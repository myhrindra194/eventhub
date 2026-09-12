import '../entities/event.dart';
import '../repositories/event_repository.dart';

class GetOrganizerEventDetailUseCase {
  final EventRepository repository;

  GetOrganizerEventDetailUseCase(this.repository);

  Future<Event?> call(String id) => repository.getEventById(id);
}
