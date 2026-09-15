import '../../domain/entities/event.dart';
import '../../domain/repositories/event_repository.dart';
import '../datasources/event_remote_datasource.dart';
import '../models/event_model.dart';

class EventRepositoryImpl implements EventRepository {
  final EventRemoteDataSource dataSource;

  EventRepositoryImpl(this.dataSource);

  @override
  Future<List<Event>> getEvents({String? category}) async {
    final models = await dataSource.getPublishedEvents();
    return _filterByCategory(models, category);
  }

  @override
  Stream<List<Event>> watchEvents({String? category}) {
    return dataSource.watchPublishedEvents().map(
      (models) => _filterByCategory(models, category),
    );
  }

  @override
  Future<Event?> getEventById(String id) async {
    final model = await dataSource.getEventById(id);
    return model?.toEntity();
  }

  @override
  Future<List<Event>> searchEvents(String query) async {
    final models = await dataSource.getPublishedEvents();
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return models.map(_toEntity).toList();

    return models
        .where(
          (model) =>
              model.title.toLowerCase().contains(normalizedQuery) ||
              model.location.toLowerCase().contains(normalizedQuery),
        )
        .map(_toEntity)
        .toList();
  }

  Event _toEntity(EventModel model) => model.toEntity();

  List<Event> _filterByCategory(List<EventModel> models, String? category) {
    final normalized = category?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty || normalized == 'all') {
      return models.map(_toEntity).toList();
    }
    return models
        .where((model) => model.category.toLowerCase() == normalized)
        .map(_toEntity)
        .toList();
  }
}
