import '../../domain/entities/event.dart';
import '../../domain/repositories/event_repository.dart';
import '../datasources/event_local_datasource.dart';

class EventRepositoryImpl implements EventRepository {
  final EventLocalDataSource dataSource;

  EventRepositoryImpl(this.dataSource);

  @override
  Future<List<Event>> getEvents({String? category}) async {
    final models = await dataSource.getEvents();
    if (category == null || category == 'All') {
      return models;
    }
    return models.where((event) => event.category == category).toList();
  }
}