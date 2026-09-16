import 'package:cloud_firestore/cloud_firestore.dart';
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

    test('generates placeholder ids of the expected shape', () {
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

  group('EventDto', () {
    Map<String, dynamic> doc({Object? tiers, Object? staffIds}) => {
      'organizerId': 'o1',
      'organizerName': 'Mirindra',
      'title': 'Concert',
      'description': 'd',
      'category': 'concert',
      'startsAt': Timestamp.fromDate(DateTime.utc(2026, 9, 20, 18)),
      'location': 'Tana',
      'imageUrl': null,
      'capacity': 120,
      'availablePlaces': 118,
      'currency': 'MGA',
      // Un `serverTimestamp` en attente se lit `null` dans le snapshot local.
      'createdAt': null,
      'tiers': ?tiers,
      'staffIds': ?staffIds,
    };

    Map<String, Object> entry(String name, int order, {int price = 0}) => {
      'name': name,
      'description': '',
      'price': price,
      'capacity': 60,
      'available': 59,
      'order': order,
    };

    test('reads a document: id injected, types sorted by order, team', () {
      final event = EventDto.fromFirestore(
        'e1',
        doc(
          tiers: {
            'tvip0001': entry('VIP', 1, price: 20000),
            'tstd0001': entry('Standard', 0),
            'broken': {'name': 'x'},
            'notamap': 3,
          },
          staffIds: ['u2', 42, ''],
        ),
      ).toDomain();
      expect(event.id, 'e1');
      expect(
        event.startsAt.isAtSameMomentAs(DateTime.utc(2026, 9, 20, 18)),
        isTrue,
      );
      expect(event.createdAt, isNull);
      expect(event.reservedCount, 2);
      expect(event.tiers.map((t) => t.id), ['tstd0001', 'tvip0001']);
      expect(event.tiers.map((t) => t.order), [0, 1]);
      expect(event.staffIds, ['u2']);
      expect(event.minPrice, 20000);
      expect(event.hasFreeTier, isTrue);
    });

    test('equal orders fall back to the id, so the list is stable', () {
      final tiers = EventDto.tiersFromMap({
        'b': entry('B', 0),
        'a': entry('A', 0),
      });
      expect(tiers.map((t) => t.id), ['a', 'b']);
    });

    test('a simple event has no types and no team', () {
      final event = EventDto.fromFirestore('e1', doc()).toDomain();
      expect(event.tiers, isEmpty);
      expect(event.staffIds, isEmpty);
    });

    test('an unknown category falls back to other', () {
      final json = doc()..['category'] = 'rave';
      expect(EventDto.fromFirestore('e1', json).category, EventCategory.other);
    });

    test('types round-trip through the stored map in form order', () {
      final written = EventDto.tiersToMap([
        tier('tb', capacity: 5, available: 4, order: 7),
        tier('ta', price: 100),
      ]);
      expect(written['tb']!['order'], 0);
      expect(written['ta']!['order'], 1);
      expect(written['tb']!.keys.toSet(), {
        'name',
        'description',
        'price',
        'capacity',
        'available',
        'order',
      });
      final read = EventDto.tiersFromMap(written);
      expect(read.map((t) => t.id), ['tb', 'ta']);
      expect(read.first.available, 4);
    });

    EventDraft draft({List<EventTierDraft> tiers = const []}) => EventDraft(
      title: 'Concert',
      description: 'd',
      category: EventCategory.concert,
      startsAt: DateTime.utc(2026, 9, 20, 18),
      location: 'Tana',
      capacity: 999,
      currency: tiers.any((t) => t.price > 0) ? 'MGA' : null,
      tiers: tiers,
    );

    // Exactement le jeu de clés d'`allow create` dans firestore.rules.
    const allowedKeys = {
      'title',
      'description',
      'category',
      'startsAt',
      'location',
      'capacity',
      'availablePlaces',
      'organizerId',
      'organizerName',
      'imageUrl',
      'createdAt',
      'updatedAt',
      'staffIds',
      'tiers',
      'currency',
    };

    test('a new simple event opens every seat, empty team, server time', () {
      final fields = EventDto.createFields(
        draft(),
        organizerId: 'o1',
        organizerName: 'Mirindra',
        plan: null,
      );
      expect(allowedKeys.containsAll(fields.keys), isTrue);
      expect(fields['capacity'], 999);
      expect(fields['availablePlaces'], 999);
      expect(fields['staffIds'], isEmpty);
      expect(fields['tiers'], isEmpty);
      expect(fields['category'], 'concert');
      expect(
        fields['startsAt'],
        Timestamp.fromDate(DateTime.utc(2026, 9, 20, 18)),
      );
      expect(fields['createdAt'], isA<FieldValue>());
      expect(fields.containsKey('updatedAt'), isFalse);
    });

    test('a new event with types takes its counters from the plan', () {
      final plan = TierPlanner.initial(const [
        EventTierDraft(name: 'Fosse', capacity: 100, price: 20000),
        EventTierDraft(name: 'Invités', capacity: 20),
      ], ids: ids);
      final fields = EventDto.createFields(
        draft(),
        organizerId: 'o1',
        organizerName: 'Mirindra',
        plan: plan,
      );
      expect(fields['capacity'], 120);
      expect(fields['availablePlaces'], 120);
      final stored = fields['tiers']! as Map<String, Map<String, Object>>;
      expect(stored, hasLength(2));
      expect(EventDto.tiersFromMap(stored).map((t) => t.name), [
        'Fosse',
        'Invités',
      ]);
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
