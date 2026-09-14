import 'package:eventhub/features/events/domain/entities/event.dart';
import 'package:eventhub/features/events/domain/entities/event_category.dart';
import 'package:eventhub/features/events/domain/recommendation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixtures.dart';

void main() {
  final now = Fixtures.now;

  Event event(
    String id, {
    EventCategory category = EventCategory.meetup,
    String organizerId = 'org-1',
    int capacity = 100,
    int? available,
    Duration startsIn = const Duration(days: 3),
  }) => Fixtures.event(
    id: id,
    capacity: capacity,
    availablePlaces: available,
    organizerId: organizerId,
    startsAt: now.add(startsIn),
  ).copyWith(category: category);

  List<String> ids(List<Recommendation> list) => [
    for (final r in list) r.event.id,
  ];

  test('suggests nothing without a personal signal', () {
    final result = Recommender.rank(
      catalogue: [event('a'), event('b')],
      favoriteIds: const {},
      bookedEventIds: const {},
      followedOrganizerIds: const {},
      now: now,
    );
    expect(result, isEmpty);
  });

  test('ranks events of followed organizers first, and says why', () {
    final result = Recommender.rank(
      catalogue: [
        event('fav', category: EventCategory.concert),
        event('same-cat', category: EventCategory.concert),
        event('followed', organizerId: 'org-9', category: EventCategory.sport),
      ],
      favoriteIds: const {'fav'},
      bookedEventIds: const {},
      followedOrganizerIds: const {'org-9'},
      now: now,
    );
    expect(ids(result), ['followed', 'same-cat']);
    expect(result.first.reason, RecommendationReason.followedOrganizer);
    expect(result.last.reason, RecommendationReason.sameCategory);
  });

  test('weighs a booking above a favourite for category affinity', () {
    final result = Recommender.rank(
      catalogue: [
        event('booked', category: EventCategory.workshop),
        event('starred', category: EventCategory.culture),
        event('workshop-2', category: EventCategory.workshop),
        event('culture-2', category: EventCategory.culture),
      ],
      favoriteIds: const {'starred'},
      bookedEventIds: const {'booked'},
      followedOrganizerIds: const {},
      now: now,
    );
    expect(ids(result), ['workshop-2', 'culture-2']);
  });

  test('excludes started, sold-out, booked and already starred events', () {
    final result = Recommender.rank(
      catalogue: [
        event(
          'started',
          organizerId: 'org-9',
          startsIn: const Duration(hours: -1),
        ),
        event('full', organizerId: 'org-9', capacity: 10, available: 0),
        event('booked', organizerId: 'org-9'),
        event('starred', organizerId: 'org-9'),
        event('ok', organizerId: 'org-9'),
      ],
      favoriteIds: const {'starred'},
      bookedEventIds: const {'booked'},
      followedOrganizerIds: const {'org-9'},
      now: now,
    );
    expect(ids(result), ['ok']);
  });

  test('breaks ties by fill rate, then by date, and honours the limit', () {
    final result = Recommender.rank(
      catalogue: [
        event('later', organizerId: 'o', startsIn: const Duration(days: 9)),
        event('sooner', organizerId: 'o', startsIn: const Duration(days: 2)),
        event('popular', organizerId: 'o', capacity: 10, available: 2),
      ],
      favoriteIds: const {},
      bookedEventIds: const {},
      followedOrganizerIds: const {'o'},
      now: now,
      limit: 2,
    );
    expect(ids(result), ['popular', 'sooner']);
  });
}
