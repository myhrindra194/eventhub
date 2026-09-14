import 'package:eventhub/features/events/application/catalogue.dart';
import 'package:eventhub/features/events/domain/entities/event.dart';
import 'package:eventhub/features/events/domain/entities/event_category.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Event event(String id, DateTime startsAt, {int available = 10}) => Event(
    id: id,
    title: 'Event $id',
    description: 'd',
    category: EventCategory.meetup,
    startsAt: startsAt,
    location: 'Antananarivo',
    capacity: 10,
    availablePlaces: available,
    organizerId: 'o1',
    organizerName: 'Mirindra',
  );

  final day = DateTime(2026, 10, 1, 18);

  test('orders by start date, then id, like the Firestore cursor', () {
    final merged = mergeCatalogue(
      [event('b', day), event('c', day.add(const Duration(days: 1)))],
      [event('a', day), event('d', day.add(const Duration(days: 2)))],
    );
    expect(merged.map((e) => e.id), ['a', 'b', 'c', 'd']);
  });

  test('the live page wins over a stale older page', () {
    final merged = mergeCatalogue(
      [event('a', day, available: 2)],
      [event('a', day, available: 9)],
    );
    expect(merged, hasLength(1));
    expect(merged.single.availablePlaces, 2);
  });

  test('CataloguePages starts empty with more to load', () {
    const pages = CataloguePages();
    expect(pages.events, isEmpty);
    expect(pages.hasMore, isTrue);
    expect(pages.copyWith(loading: true).loading, isTrue);
  });
}
