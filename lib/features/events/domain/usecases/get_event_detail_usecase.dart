import '../entities/event.dart';
import '../repositories/event_repository.dart';

class GetEventDetailUseCase {
  final EventRepository repository;

  GetEventDetailUseCase(this.repository);

  Future<Event?> call(String id) async {
    final events = await repository.getEvents();
    try {
      return events.firstWhere((event) => event.id == id);
    } catch (_) {
      return null;
    }
  }
}