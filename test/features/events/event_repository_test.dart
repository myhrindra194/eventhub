import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/events/data/datasources/event_remote_data_source.dart';
import 'package:eventhub/features/events/data/repositories/event_repository_impl.dart';
import 'package:eventhub/features/events/domain/entities/event.dart';
import 'package:eventhub/features/events/domain/entities/event_category.dart';
import 'package:eventhub/features/events/domain/entities/event_draft.dart';
import 'package:eventhub/features/events/domain/entities/event_tier.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fixtures.dart';

class _MockRemote extends Mock implements EventRemoteDataSource {}

void main() {
  late _MockRemote remote;
  late EventRepositoryImpl repo;

  final organizer = Fixtures.organizer.copyWith(emailVerified: true);

  EventDraft draft({
    int capacity = 50,
    List<EventTierDraft> tiers = const [],
    String? imageUrl,
  }) => EventDraft(
    title: 'Flutter Meetup',
    description: 'Rencontre.',
    category: EventCategory.meetup,
    startsAt: Fixtures.now.add(const Duration(days: 3)),
    location: 'Antananarivo',
    capacity: capacity,
    tiers: tiers,
    imageUrl: imageUrl,
  );

  BusinessRule? ruleOf(Result<Object?> result) => switch (result) {
    Err(failure: final BusinessRuleFailure f) => f.rule,
    _ => null,
  };

  setUpAll(() {
    registerFallbackValue(draft());
    registerFallbackValue(
      (Event _) => (failure: null as Failure?, edit: null as EventEdit?),
    );
  });

  setUp(() {
    remote = _MockRemote();
    repo = EventRepositoryImpl(remote: remote, clock: () => Fixtures.now);
  });

  group('create', () {
    void stubCreate() => when(
      () => remote.create(
        draft: any(named: 'draft'),
        plan: any(named: 'plan'),
        organizerId: any(named: 'organizerId'),
        organizerName: any(named: 'organizerName'),
      ),
    ).thenAnswer((_) async => 'e-new');

    test('publishes with the profile name and a trimmed cover', () async {
      stubCreate();
      final result = await repo.create(
        draft: draft(imageUrl: '  https://cdn.example.com/a.jpg '),
        organizer: organizer,
      );
      expect(result, const Ok('e-new'));
      final captured = verify(
        () => remote.create(
          draft: captureAny(named: 'draft'),
          plan: null,
          organizerId: 'org-1',
          organizerName: 'Mirindra',
        ),
      ).captured;
      expect(
        (captured.single as EventDraft).imageUrl,
        'https://cdn.example.com/a.jpg',
      );
    });

    test('plans ticket types so every seat of every type is free', () async {
      stubCreate();
      await repo.create(
        draft: draft(
          tiers: const [
            EventTierDraft(name: 'Standard', capacity: 40),
            EventTierDraft(name: 'VIP', capacity: 10),
          ],
        ),
        organizer: organizer,
      );
      final plan =
          verify(
                () => remote.create(
                  draft: any(named: 'draft'),
                  plan: captureAny(named: 'plan'),
                  organizerId: any(named: 'organizerId'),
                  organizerName: any(named: 'organizerName'),
                ),
              ).captured.single
              as TierPlan;
      expect(plan.capacity, 50);
      expect(plan.available, 50);
    });

    test('refuses a participant, an unverified address, a bad link', () async {
      expect(
        await repo.create(draft: draft(), organizer: Fixtures.participant),
        isA<Err<String>>().having(
          (e) => e.failure,
          'failure',
          isA<PermissionFailure>(),
        ),
      );
      expect(
        ruleOf(
          await repo.create(draft: draft(), organizer: Fixtures.organizer),
        ),
        BusinessRule.emailNotVerified,
      );
      expect(
        await repo.create(
          draft: draft(imageUrl: 'http://insecure.example/a.jpg'),
          organizer: organizer,
        ),
        isA<Err<String>>().having(
          (e) => (e.failure as ValidationFailure).fieldErrors.keys,
          'fields',
          contains('imageUrl'),
        ),
      );
      verifyNever(
        () => remote.create(
          draft: any(named: 'draft'),
          plan: any(named: 'plan'),
          organizerId: any(named: 'organizerId'),
          organizerName: any(named: 'organizerName'),
        ),
      );
    });
  });

  group('update', () {
    /// Runs the decision against [current], as the transaction would.
    void stubUpdate(Event current) =>
        when(() => remote.update(any(), any())).thenAnswer((invocation) async {
          final decide = invocation.positionalArguments[1] as EventEditDecision;
          return decide(current).failure;
        });

    test('keeps the seats taken when the capacity changes', () {
      final (:failure, :edit) = EventRepositoryImpl.planEdit(
        current: Fixtures.event(availablePlaces: 70),
        draft: draft(capacity: 120),
        user: organizer,
      );
      expect(failure, isNull);
      expect(edit!.capacity, 120);
      expect(edit.availablePlaces, 90);
      expect(edit.tiers, isEmpty);
    });

    test('keeps what each type sold', () {
      final (:failure, :edit) = EventRepositoryImpl.planEdit(
        current: Fixtures.event(
          capacity: 50,
          availablePlaces: 45,
          tiers: const [
            EventTier(
              id: 'tstd',
              name: 'Standard',
              capacity: 50,
              available: 45,
            ),
          ],
        ),
        draft: draft(
          tiers: const [
            EventTierDraft(id: 'tstd', name: 'Standard', capacity: 60),
          ],
        ),
        user: organizer,
      );
      expect(failure, isNull);
      expect(edit!.capacity, 60);
      expect(edit.availablePlaces, 55);
      expect(edit.tiers.single.id, 'tstd');
    });

    test('a co-organizer edits; a stranger gets the precise rule', () {
      const stranger = Fixtures.organizer;
      final event = Fixtures.event(organizerId: 'someone', staffIds: ['org-1']);
      expect(
        EventRepositoryImpl.planEdit(
          current: event,
          draft: draft(),
          user: stranger,
        ).failure,
        isNull,
      );
      expect(
        (EventRepositoryImpl.planEdit(
                  current: Fixtures.event(organizerId: 'someone'),
                  draft: draft(),
                  user: stranger,
                ).failure!
                as BusinessRuleFailure)
            .rule,
        BusinessRule.notEventOwner,
      );
    });

    test('returns the refusal decided inside the transaction', () async {
      stubUpdate(Fixtures.event(availablePlaces: 40));
      final result = await repo.update(
        eventId: 'evt-1',
        draft: draft(capacity: 10),
        organizer: organizer,
      );
      expect(ruleOf(result), BusinessRule.capacityBelowReservations);
    });

    test('an invalid draft never opens a transaction', () async {
      final result = await repo.update(
        eventId: 'evt-1',
        draft: draft(capacity: 0),
        organizer: organizer,
      );
      expect(result, isA<Err<void>>());
      verifyNever(() => remote.update(any(), any()));
    });
  });

  group('delete', () {
    test('refuses an event with bookings before writing', () async {
      when(
        () => remote.getById('evt-1'),
      ).thenAnswer((_) async => Fixtures.event(availablePlaces: 99));
      final result = await repo.delete(eventId: 'evt-1', organizer: organizer);
      expect(ruleOf(result), BusinessRule.eventHasReservations);
      verifyNever(
        () => remote.delete(
          eventId: any(named: 'eventId'),
          organizerId: any(named: 'organizerId'),
        ),
      );
    });

    test('deletes an empty event of its owner', () async {
      when(
        () => remote.getById('evt-1'),
      ).thenAnswer((_) async => Fixtures.event());
      when(
        () => remote.delete(eventId: 'evt-1', organizerId: 'org-1'),
      ).thenAnswer((_) async {});
      expect(
        await repo.delete(eventId: 'evt-1', organizer: organizer),
        isA<Ok<void>>(),
      );
    });
  });
}
