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
    const vipId = '0b8e3f5c-9d1a-4c2e-8f7a-1234567890ab';
    const stdId = '7c1d2e3f-4a5b-4c6d-8e9f-abcdefabcdef';

    Map<String, dynamic> row({
      List<Map<String, dynamic>>? tiers,
      List<Map<String, dynamic>>? staff,
    }) => {
      'id': 'e1',
      'organizer_id': 'o1',
      'organizer_name': 'Mirindra',
      'title': 'Concert',
      'description': 'd',
      'category': 'concert',
      'starts_at': '2026-09-20T18:00:00+00:00',
      'location': 'Tana',
      'image_url': null,
      'capacity': 120,
      'available_places': 118,
      'currency': 'MGA',
      'created_at': '2026-09-01T08:00:00+00:00',
      'updated_at': '2026-09-01T08:00:00+00:00',
      'event_tiers': ?tiers,
      'event_staff': ?staff,
    };

    Map<String, dynamic> tierRow(String id, int position, {int price = 0}) => {
      'id': id,
      'event_id': 'e1',
      'name': id == vipId ? 'VIP' : 'Standard',
      'price': price,
      'capacity': 60,
      'available': 59,
      'position': position,
    };

    test('reads a row with embedded types (sorted by position) and team', () {
      final event = EventDto.fromJson(
        row(
          tiers: [tierRow(vipId, 1, price: 20000), tierRow(stdId, 0)],
          staff: [
            {'user_id': 'u2'},
            {'bad': 1},
          ],
        ),
      ).toDomain();
      expect(
        event.startsAt.isAtSameMomentAs(DateTime.utc(2026, 9, 20, 18)),
        isTrue,
      );
      expect(event.reservedCount, 2);
      expect(event.tiers.map((t) => t.id), [stdId, vipId]);
      expect(event.tiers.map((t) => t.order), [0, 1]);
      expect(event.staffIds, ['u2']);
      expect(event.minPrice, 20000);
      expect(event.hasFreeTier, isTrue);
    });

    test('a Realtime row has no relations; the stream supplies them', () {
      final dto = EventDto.fromJson(row());
      expect(dto.toDomain().tiers, isEmpty);
      final event = dto.toDomain(
        tiers: [EventTierDto.fromJson(tierRow(vipId, 0, price: 100))],
        staffIds: const ['u3'],
      );
      expect(event.tiers.single.price, 100);
      expect(event.staffIds, ['u3']);
    });

    test('an unknown category falls back to other', () {
      final json = row()..['category'] = 'rave';
      expect(EventDto.fromJson(json).category, EventCategory.other);
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

    test('save_event payload without types sends the capacity', () {
      final payload = EventDto.saveEventPayload(draft());
      expect(payload.containsKey('id'), isFalse);
      expect(payload['capacity'], 999);
      expect(payload['starts_at'], '2026-09-20T18:00:00.000Z');
      expect(payload['category'], 'concert');
      expect(payload['tiers'], isEmpty);
      expect(payload.containsKey('currency'), isFalse);
    });

    test('save_event payload with types sends the draft, no seat counts', () {
      final payload = EventDto.saveEventPayload(
        draft(
          tiers: const [
            EventTierDraft(
              id: vipId,
              name: 'Fosse',
              capacity: 100,
              price: 20000,
            ),
            EventTierDraft(id: 'tplaceho', name: 'Invités', capacity: 20),
          ],
        ),
        eventId: 'e1',
      );
      expect(payload['id'], 'e1');
      expect(payload.containsKey('capacity'), isFalse);
      expect(payload['currency'], 'MGA');
      expect(payload['tiers'], [
        {
          'id': vipId,
          'name': 'Fosse',
          'description': '',
          'price': 20000,
          'capacity': 100,
        },
        {'name': 'Invités', 'description': '', 'price': 0, 'capacity': 20},
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
