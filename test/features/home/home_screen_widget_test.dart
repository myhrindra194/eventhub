import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eventhub/features/events/domain/entities/event.dart';
import 'package:eventhub/features/events/domain/repositories/event_repository.dart';
import 'package:eventhub/features/events/presentation/providers/events_provider.dart';
import 'package:eventhub/features/home/presentation/views/home_screen.dart';
import '../events/event_fixtures.dart';

/// Teste le bug n°1 corrigé en Phase 1 : le filtre catégorie du Home
/// comparait un enum à une String (comparaison toujours fausse → liste vide).
void main() {
  late FakeEventRepository repository;

  setUp(() {
    repository = FakeEventRepository();
  });

  Future<void> pumpHome(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [eventRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    // Un cycle pour laisser le FutureProvider résoudre.
    await tester.pumpAndSettle();
  }

  testWidgets('affiche tous les événements quand "All" est sélectionné', (
    tester,
  ) async {
    repository.events = [
      buildEventEntity(
        title: 'Tech Meetup',
        category: EventCategory.conference,
      ),
      buildEventEntity(
        id: 'event-2',
        title: 'Concert Lyon',
        category: EventCategory.concert,
      ),
    ];

    await pumpHome(tester);

    expect(find.text('Tech Meetup'), findsOneWidget);
    expect(find.text('Concert Lyon'), findsOneWidget);
  });

  testWidgets('filtre les événements quand une catégorie est sélectionnée', (
    tester,
  ) async {
    repository.events = [
      buildEventEntity(
        title: 'Tech Meetup',
        category: EventCategory.conference,
      ),
      buildEventEntity(
        id: 'event-2',
        title: 'Concert Lyon',
        category: EventCategory.concert,
      ),
    ];

    await pumpHome(tester);

    // On pilote le notifier via le conteneur Riverpod : c'est la même chaîne
    // de production que le tap sur le chip (notifier -> StreamProvider -> UI),
    // sans dépendre du hit-testing d'un chip éventuellement scrollé hors
    // écran.
    final container = ProviderScope.containerOf(
      tester.element(find.byType(HomeScreen)),
    );
    container.read(selectedCategoryProvider.notifier).setCategory('Concert');
    await tester.pumpAndSettle();

    expect(find.text('Tech Meetup'), findsNothing);
    expect(find.text('Concert Lyon'), findsOneWidget);
  });
}

/// Fake minimaliste : le Home consomme uniquement `watchEvents`.
/// Il applique le même filtre que `EventRepositoryImpl` pour respecter
/// le contrat (sinon le test valide un comportement fictif).
class FakeEventRepository implements EventRepository {
  List<Event> events = [];

  List<Event> _filter(String? category) {
    final normalized = category?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty || normalized == 'all') {
      return events;
    }
    return events
        .where((event) => event.category.name.toLowerCase() == normalized)
        .toList();
  }

  @override
  Future<List<Event>> getEvents({String? category}) async => _filter(category);

  @override
  Stream<List<Event>> watchEvents({String? category}) =>
      Stream.value(_filter(category));

  @override
  Future<Event?> getEventById(String id) async {
    for (final event in events) {
      if (event.id == id) return event;
    }
    return null;
  }

  @override
  Future<List<Event>> searchEvents(String query) async => events;
}
