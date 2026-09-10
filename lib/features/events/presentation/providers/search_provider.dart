import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/event.dart';
import '../../domain/usecases/search_events_usecase.dart';
import 'events_provider.dart';

// 1. Provider du UseCase utilisant eventRepositoryProvider de events_provider.dart
final searchEventsUseCaseProvider = Provider<SearchEventsUseCase>((ref) {
  final repository = ref.watch(eventRepositoryProvider);
  return SearchEventsUseCase(repository);
});

// 2. Notifier for the search keyword.
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) {
    state = query;
  }
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);

// 3. AsyncNotifier for result management.
class SearchNotifier extends AsyncNotifier<List<Event>> {
  @override
  Future<List<Event>> build() async {
    return search('Jazz Night');
  }

  Future<List<Event>> search(String query) async {
    state = const AsyncValue.loading();
    try {
      final useCase = ref.read(searchEventsUseCaseProvider);
      final results = await useCase(query);
      state = AsyncValue.data(results);
      return results;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final searchEventsNotifierProvider =
    AsyncNotifierProvider<SearchNotifier, List<Event>>(SearchNotifier.new);
