import '../repositories/event_repository.dart';

class PublishEventUseCase {
  final EventRepository repository;

  PublishEventUseCase(this.repository);

  Future<void> call(String id) => repository.publishEvent(id);
}
