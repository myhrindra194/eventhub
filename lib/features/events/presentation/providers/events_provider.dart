import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/auth_dependencies.dart';
import '../../data/datasources/event_remote_datasource.dart';
import '../../data/repositories/event_repository_impl.dart';
import '../../domain/entities/event.dart';
import '../../domain/repositories/event_repository.dart';
import '../../domain/usecases/get_events_usecase.dart';
import '../../domain/usecases/get_event_detail_usecase.dart';

// State notifier for the selected category.
class SelectedCategoryNotifier extends Notifier<String> {
  @override
  String build() => 'All';

  void setCategory(String category) {
    state = category;
  }
}

final selectedCategoryProvider =
    NotifierProvider<SelectedCategoryNotifier, String>(
      SelectedCategoryNotifier.new,
    );

// Injection des UseCases
final eventRepositoryProvider = Provider<EventRepository>((ref) {
  final dataSource = EventRemoteDataSource(ref.watch(firestoreProvider));
  return EventRepositoryImpl(dataSource);
});

final getEventsUseCaseProvider = Provider<GetEventsUseCase>((ref) {
  final repository = ref.watch(eventRepositoryProvider);
  return GetEventsUseCase(repository);
});

final getEventDetailUseCaseProvider = Provider<GetEventDetailUseCase>((ref) {
  final repository = ref.watch(eventRepositoryProvider);
  return GetEventDetailUseCase(repository);
});

// Asynchronous event retrieval.
final eventsFutureProvider = FutureProvider<List<Event>>((ref) async {
  final useCase = ref.watch(getEventsUseCaseProvider);
  final category = ref.watch(selectedCategoryProvider);
  return await useCase(category: category);
});

/// Flux temps réel : le home se met à jour quand un organisateur publie,
/// modifie (places restantes) ou supprime un événement.
final eventsStreamProvider = StreamProvider<List<Event>>((ref) {
  final category = ref.watch(selectedCategoryProvider);
  return ref.watch(eventRepositoryProvider).watchEvents(category: category);
});

// Retrieve an event by ID.
final eventDetailProvider = FutureProvider.family<Event?, String>((
  ref,
  id,
) async {
  final useCase = ref.watch(getEventDetailUseCaseProvider);
  return await useCase(id);
});
