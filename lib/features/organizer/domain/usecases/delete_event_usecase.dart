import '../repositories/event_repository.dart';

class DeleteEventUseCase {
  final EventRepository repository;

  DeleteEventUseCase(this.repository);

  Future<void> call(String id) => repository.deleteEvent(id);
}
