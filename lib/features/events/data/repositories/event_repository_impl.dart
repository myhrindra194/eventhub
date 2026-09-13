import '../../domain/entities/event.dart';
import '../../domain/repositories/event_repository.dart';
import '../datasources/event_remote_datasource.dart';

class EventRepositoryImpl implements EventRepository {
  final EventRemoteDataSource dataSource;

  EventRepositoryImpl(this.dataSource);

  @override
  Future<List<Event>> getEvents({String? category}) async {
    final events = (await dataSource.getPublishedEvents())
        .map((model) => model.toEntity())
        .toList();
    if (category == null || category == 'All') {
      return events;
    }
    // ignore: unrelated_type_equality_checks
    return events.where((event) => event.category == category).toList();
  }

  @override
  Future<List<Event>> searchEvents(String query) async {
    final events = (await dataSource.getPublishedEvents())
        .map((model) => model.toEntity())
        .toList();
    final normalizedQuery = query.toLowerCase();
    return events
        .where((event) => event.title.toLowerCase().contains(normalizedQuery))
        .toList();
  }
}
