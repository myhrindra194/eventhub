import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/events/data/dtos/event_dto.dart';
import 'package:eventhub/features/events/domain/entities/event_category.dart';
import 'package:eventhub/features/events/domain/entities/event_draft.dart';
import 'package:eventhub/features/events/domain/entities/event_tier.dart';
import 'package:eventhub/features/events/presentation/widgets/ticket_types.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixtures.dart';

void main() {
  EventTier tier(
    String id, {
    int price = 0,
    int capacity = 10,
    int? available,
    int order = 0,
  }) => EventTier(
    id: id,
    name: id.toUpperCase(),
    price: price,
    capacity: capacity,
    available: available ?? capacity,
    order: order,
  );

  var counter = 0;
  String ids() => 'n${counter++}';

  BusinessRule? rule<T>(Result<T> r) => switch (r) {
    Err(failure: final BusinessRuleFailure f) => f.rule,
    _ => null,
  };

  group('TierPlanner.initial', () {
    test('opens every seat and sums the capacity', () {
      final plan = TierPlanner.initial([
        const EventTierDraft(name: 'Standard', capacity: 40),
        const EventTierDraft(name: 'VIP', capacity: 10, price: 2500),
      ], ids: ids);
      expect(plan.capacity, 50);
      expect(plan.available, 50);
      expect(plan.hasPaid, isTrue);
      expect(plan.tiers.map((t) => t.order), [0, 1]);
      expect(plan.tiers.every((t) => EventTier.isValidId(t.id)), isTrue);
    });

    test('generates ids fit for field paths', () {
      expect(EventTier.isValidId(TierPlanner.newId()), isTrue);
      expect(EventTier.isValidId('bad id'), isFalse);
    });
  });

  group('TierPlanner.apply', () {
    final current = [
      tier('std', capacity: 40, available: 30),
      tier('vip', price: 2500, available: 10, order: 1),
    ];

    test('keeps what each type sold, and adds new types', () {
      final result = TierPlanner.apply(
        soldWithoutTiers: 0,
        current: current,
        drafts: const [
          EventTierDraft(id: 'std', name: 'Standard', capacity: 50),
          EventTierDraft(id: 'vip', name: 'VIP', capacity: 12, price: 3000),
          EventTierDraft(name: 'Étudiant', capacity: 5),
        ],
        ids: ids,
      );
      final plan = (result as Ok<TierPlan?>).value!;
      expect(plan.tiers.map((t) => t.available), [40, 12, 5]);
      expect(plan.capacity, 67);
      expect(plan.available, 57);
    });

    test(
      'refuses going below the seats sold, or removing a type that sold',
      () {
        expect(
          rule(
            TierPlanner.apply(
              soldWithoutTiers: 0,
              current: current,
              drafts: const [
                EventTierDraft(id: 'std', name: 'Standard', capacity: 5),
                EventTierDraft(id: 'vip', name: 'VIP', capacity: 10),
              ],
            ),
          ),
          BusinessRule.capacityBelowReservations,
        );
        expect(
          rule(
            TierPlanner.apply(
              soldWithoutTiers: 0,
              current: current,
              drafts: const [
                EventTierDraft(id: 'vip', name: 'VIP', capacity: 10),
              ],
            ),
          ),
          BusinessRule.tiersLocked,
        );
      },
    );

    test('lets an unsold type go', () {
      final result = TierPlanner.apply(
        soldWithoutTiers: 0,
        current: current,
        drafts: const [
          EventTierDraft(id: 'std', name: 'Standard', capacity: 40),
        ],
      );
      expect((result as Ok<TierPlan?>).value!.tiers, hasLength(1));
    });

    test('locks the mode once seats were sold in it', () {
      expect(
        rule(
          TierPlanner.apply(
            soldWithoutTiers: 3,
            current: const [],
            drafts: const [EventTierDraft(name: 'Standard', capacity: 10)],
          ),
        ),
        BusinessRule.tiersLocked,
      );
      expect(
        rule(
          TierPlanner.apply(
            soldWithoutTiers: 0,
            current: current,
            drafts: const [],
          ),
        ),
        BusinessRule.tiersLocked,
      );
      expect(
        TierPlanner.apply(
          soldWithoutTiers: 0,
          current: const [],
          drafts: const [],
        ),
        isA<Ok<TierPlan?>>().having((r) => r.value, 'value', isNull),
      );
    });
  });

  group('EventDto tiers', () {
    test('round-trips, sorted by order, skipping malformed entries', () {
      final map = EventDto.tiersToMap([
        tier('vip', price: 2500, order: 1),
        tier('std'),
      ]);
      final read = EventDto.tiersFromMap({
        ...map,
        'bad id': {'name': 'x'},
        'broken': 'nope',
      });
      expect(read.map((t) => t.id), ['std', 'vip']);
      expect(read.last.price, 2500);
    });

    test('a draft with types becomes an event whose totals are their sums', () {
      final dto = EventDto.fromDraft(
        EventDraft(
          title: 'Concert',
          description: 'd',
          category: EventCategory.concert,
          startsAt: Fixtures.now.add(const Duration(days: 3)),
          location: 'Tana',
          capacity: 999,
          currency: 'MGA',
          tiers: const [
            EventTierDraft(name: 'Fosse', capacity: 100, price: 20000),
            EventTierDraft(name: 'Invités', capacity: 20),
          ],
        ),
        organizerId: 'o1',
        organizerName: 'Mirindra',
        tierIds: ids,
      );
      expect(dto.capacity, 120);
      expect(dto.availablePlaces, 120);
      expect(dto.currency, 'MGA');
      expect(dto.tiers, hasLength(2));
      final event = dto.toDomain('e1');
      expect(event.minPrice, 20000);
      expect(event.hasFreeTier, isTrue);
      expect(event.isFree, isFalse);
    });
  });

  group('EventDraft validation with types', () {
    EventDraft draft(List<EventTierDraft> tiers, {String? currency}) =>
        EventDraft(
          title: 'Concert',
          description: 'd',
          category: EventCategory.concert,
          startsAt: Fixtures.now.add(const Duration(days: 3)),
          location: 'Tana',
          capacity: 0,
          tiers: tiers,
          currency: currency,
        );

    Map<String, String> errors(EventDraft d) =>
        switch (d.validate(now: Fixtures.now)) {
          Err(failure: final ValidationFailure f) => f.fieldErrors,
          _ => const {},
        };

    test('asks for a currency as soon as one type is paid', () {
      expect(
        errors(
          draft(const [EventTierDraft(name: 'VIP', capacity: 5, price: 100)]),
        ),
        contains('currency'),
      );
    });

    test('refuses duplicate names and empty types', () {
      expect(
        errors(
          draft(const [
            EventTierDraft(name: 'Standard', capacity: 5),
            EventTierDraft(name: 'standard ', capacity: 5),
          ]),
        ),
        contains('tiers'),
      );
      expect(
        errors(draft(const [EventTierDraft(name: 'Standard', capacity: 0)])),
        contains('tiers'),
      );
    });

    test(
      'a valid draft carries the summed capacity and drops a useless currency',
      () {
        final result = draft(const [
          EventTierDraft(name: ' Standard ', capacity: 5),
          EventTierDraft(name: 'Tribune', capacity: 7),
        ], currency: 'EUR').validate(now: Fixtures.now);
        final valid = (result as Ok<EventDraft>).value;
        expect(valid.capacity, 12);
        expect(valid.currency, isNull);
        expect(valid.tiers.first.name, 'Standard');
      },
    );
  });

  group('eventPriceLabel', () {
    test('says free, a single price, a starting price, or both', () {
      expect(eventPriceLabel(Fixtures.event()), 'Gratuit');
      expect(
        eventPriceLabel(
          Fixtures.event(currency: 'EUR', tiers: [tier('vip', price: 2500)]),
        ).replaceAll(RegExp(r'\s'), ' '),
        '25,00 €',
      );
      expect(
        eventPriceLabel(
          Fixtures.event(
            currency: 'EUR',
            tiers: [tier('a', price: 1500), tier('b', price: 3000, order: 1)],
          ),
        ).replaceAll(RegExp(r'\s'), ' '),
        'Dès 15,00 €',
      );
      expect(
        eventPriceLabel(
          Fixtures.event(
            currency: 'EUR',
            tiers: [tier('a'), tier('b', price: 3000, order: 1)],
          ),
        ),
        'Gratuit ou payant',
      );
    });
  });
}
