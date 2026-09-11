import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/events/domain/entities/event_category.dart';
import 'package:eventhub/features/events/domain/entities/event_draft.dart';
import 'package:eventhub/features/events/domain/policies/event_policy.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fixtures.dart';

void main() {
  group('Event', () {
    test('derives reservedCount, isFull and fillRate', () {
      final event = Fixtures.event(availablePlaces: 99);
      expect(event.reservedCount, 1);
      expect(event.isFull, isFalse);
      expect(event.fillRate, closeTo(0.01, 1e-9));
      expect(Fixtures.event(capacity: 5, availablePlaces: 0).isFull, isTrue);
    });

    test('hasStarted compares against the injected clock', () {
      final event = Fixtures.event(startsAt: Fixtures.now);
      expect(event.hasStarted(Fixtures.now), isTrue);
      expect(
        event.hasStarted(Fixtures.now.subtract(const Duration(seconds: 1))),
        isFalse,
      );
    });
  });

  group('EventPolicy.canManage', () {
    test('allows the owning organizer', () {
      expect(
        EventPolicy.canManage(
          event: Fixtures.event(),
          user: Fixtures.organizer,
        ),
        isA<Ok<void>>(),
      );
    });

    test('rejects another organizer', () {
      final result = EventPolicy.canManage(
        event: Fixtures.event(organizerId: 'someone-else'),
        user: Fixtures.organizer,
      );
      expect(result, isA<Err<void>>());
      expect(
        (result as Err<void>).failure,
        isA<BusinessRuleFailure>().having(
          (f) => f.rule,
          'rule',
          BusinessRule.notEventOwner,
        ),
      );
    });

    test('rejects a participant even on a matching id', () {
      final result = EventPolicy.canManage(
        event: Fixtures.event(organizerId: Fixtures.participant.id),
        user: Fixtures.participant,
      );
      expect(result, isA<Err<void>>());
    });
  });

  group('EventPolicy.availablePlacesAfterCapacityChange', () {
    test('keeps existing reservations when capacity grows', () {
      final event = Fixtures.event(availablePlaces: 90);
      final result = EventPolicy.availablePlacesAfterCapacityChange(
        event: event,
        newCapacity: 120,
      );
      expect(result, const Ok<int>(110));
    });

    test('rejects a capacity below the reserved count', () {
      final event = Fixtures.event(availablePlaces: 90);
      final result = EventPolicy.availablePlacesAfterCapacityChange(
        event: event,
        newCapacity: 5,
      );
      expect(result, isA<Err<int>>());
    });
  });

  group('EventDraft.validate', () {
    EventDraft draft({
      String title = 'Flutter Meetup',
      int capacity = 100,
      DateTime? startsAt,
    }) => EventDraft(
      title: title,
      description: 'desc',
      category: EventCategory.meetup,
      startsAt: startsAt ?? Fixtures.now.add(const Duration(days: 1)),
      location: 'Tana',
      capacity: capacity,
    );

    test('accepts a valid draft and trims strings', () {
      final result = draft(
        title: '  Flutter Meetup  ',
      ).validate(now: Fixtures.now);
      expect(result.valueOrNull?.title, 'Flutter Meetup');
    });

    test('collects every field error at once', () {
      final result = draft(
        title: 'ab',
        capacity: 0,
        startsAt: Fixtures.now.subtract(const Duration(days: 1)),
      ).validate(now: Fixtures.now);

      final failure = (result as Err<EventDraft>).failure as ValidationFailure;
      expect(
        failure.fieldErrors.keys,
        containsAll(['title', 'capacity', 'startsAt']),
      );
    });
  });
}
