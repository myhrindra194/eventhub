import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/events/domain/entities/event_tier.dart';
import 'package:eventhub/features/reservations/domain/entities/reservation.dart';
import 'package:eventhub/features/reservations/domain/policies/reservation_policy.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fixtures.dart';

void main() {
  group('ReservationPolicy.canReserve', () {
    test('allows a first reservation on an open, upcoming event', () {
      final result = ReservationPolicy.canReserve(
        event: Fixtures.event(),
        existing: null,
        now: Fixtures.now,
      );
      expect(result, isA<Ok<void>>());
    });

    test('rejects a second active reservation by the same participant', () {
      final result = ReservationPolicy.canReserve(
        event: Fixtures.event(),
        existing: Fixtures.reservation(),
        now: Fixtures.now,
      );
      expect(_rule(result), BusinessRule.alreadyReserved);
    });

    test('allows re-booking after a cancellation', () {
      final result = ReservationPolicy.canReserve(
        event: Fixtures.event(),
        existing: Fixtures.reservation(status: ReservationStatus.cancelled),
        now: Fixtures.now,
      );
      expect(result, isA<Ok<void>>());
    });

    test('rejects when the event is full', () {
      final result = ReservationPolicy.canReserve(
        event: Fixtures.event(capacity: 10, availablePlaces: 0),
        existing: null,
        now: Fixtures.now,
      );
      expect(_rule(result), BusinessRule.eventFull);
    });

    test('rejects when the event has already started', () {
      final result = ReservationPolicy.canReserve(
        event: Fixtures.event(
          startsAt: Fixtures.now.subtract(const Duration(minutes: 1)),
        ),
        existing: null,
        now: Fixtures.now,
      );
      expect(_rule(result), BusinessRule.eventAlreadyStarted);
    });

    test("an organizer account books someone else's event", () {
      final result = ReservationPolicy.canReserve(
        event: Fixtures.event(organizerId: 'another-organizer'),
        existing: null,
        now: Fixtures.now,
        userId: Fixtures.organizer.id,
      );
      expect(result, isA<Ok<void>>());
    });

    test('the event team does not book its own event', () {
      for (final event in [
        Fixtures.event(),
        Fixtures.event(organizerId: 'owner', staffIds: [Fixtures.organizer.id]),
      ]) {
        final result = ReservationPolicy.canReserve(
          event: event,
          existing: null,
          now: Fixtures.now,
          userId: Fixtures.organizer.id,
        );
        expect((result as Err<void>).failure, isA<PermissionFailure>());
      }
    });

    test('checks "already reserved" before "full"', () {
      // Un participant qui détient la dernière place doit recevoir le message
      // précis, et non un « complet » qui ne lui apprendrait rien.
      final result = ReservationPolicy.canReserve(
        event: Fixtures.event(capacity: 1, availablePlaces: 0),
        existing: Fixtures.reservation(),
        now: Fixtures.now,
      );
      expect(_rule(result), BusinessRule.alreadyReserved);
    });
  });

  group('ReservationPolicy.canCancel', () {
    test('allows the owner to cancel an active reservation', () {
      final result = ReservationPolicy.canCancel(
        reservation: Fixtures.reservation(),
        userId: Fixtures.participant.id,
      );
      expect(result, isA<Ok<void>>());
    });

    test('rejects cancelling someone else\'s reservation', () {
      final result = ReservationPolicy.canCancel(
        reservation: Fixtures.reservation(),
        userId: 'intruder',
      );
      expect(_rule(result), BusinessRule.notReservationOwner);
    });

    test('rejects cancelling an already cancelled reservation', () {
      final result = ReservationPolicy.canCancel(
        reservation: Fixtures.reservation(status: ReservationStatus.cancelled),
        userId: Fixtures.participant.id,
      );
      expect(_rule(result), BusinessRule.reservationNotActive);
    });
  });

  group('with ticket types and payments', () {
    final event = Fixtures.event(
      capacity: 15,
      availablePlaces: 13,
      currency: 'EUR',
      tiers: const [
        EventTier(id: 'std', name: 'Standard', capacity: 10, available: 10),
        EventTier(
          id: 'vip',
          name: 'VIP',
          capacity: 5,
          available: 3,
          price: 2500,
          order: 1,
        ),
        EventTier(
          id: 'full',
          name: 'Early',
          capacity: 2,
          available: 0,
          order: 2,
        ),
      ],
    );

    Result<void> reserve({String? tierId, Reservation? existing}) =>
        ReservationPolicy.canReserve(
          event: event,
          existing: existing,
          now: Fixtures.now,
          tierId: tierId,
        );

    test('books a free type directly', () {
      expect(reserve(tierId: 'std'), isA<Ok<void>>());
    });

    test('asks for a type, refuses a sold-out one and a paid one', () {
      expect(_rule(reserve()), BusinessRule.tierRequired);
      expect(_rule(reserve(tierId: 'nope')), BusinessRule.tierRequired);
      expect(_rule(reserve(tierId: 'full')), BusinessRule.tierSoldOut);
      final paid = reserve(tierId: 'vip');
      expect(_rule(paid), BusinessRule.paymentRequired);
      // Faute de serveur de paiement, la phrase le dit sans détour.
      expect(
        (paid as Err<void>).failure.message,
        ReservationPolicy.paymentUnavailable.message,
      );
    });

    test('refuses a second purchase while one is being paid', () {
      final pending = Fixtures.reservation(status: ReservationStatus.pending);
      expect(
        _rule(reserve(tierId: 'std', existing: pending)),
        BusinessRule.paymentPending,
      );
    });

    test(
      'checkout accepts a paid type, resumes a held one, refuses a free one',
      () {
        Result<EventTier> checkout(String tierId, {Reservation? existing}) =>
            ReservationPolicy.canCheckout(
              event: event,
              existing: existing,
              now: Fixtures.now,
              tierId: tierId,
            );
        expect(checkout('vip'), isA<Ok<EventTier>>());
        expect(
          checkout(
            'vip',
            existing: Fixtures.reservation(status: ReservationStatus.pending),
          ),
          isA<Ok<EventTier>>(),
        );
        expect(switch (checkout('std')) {
          Err(failure: final BusinessRuleFailure f) => f.rule,
          _ => null,
        }, BusinessRule.actionRefused);
      },
    );

    test(
      'a paid ticket is refunded, not cancelled, and only before the start',
      () {
        final paid = Fixtures.reservation().copyWith(
          tierId: 'vip',
          tierName: 'VIP',
          pricePaid: 2500,
          currency: 'EUR',
        );
        expect(
          _rule(
            ReservationPolicy.canCancel(
              reservation: paid,
              userId: Fixtures.participant.id,
            ),
          ),
          BusinessRule.refundRequired,
        );
        expect(
          ReservationPolicy.canRefund(
            reservation: paid,
            userId: Fixtures.participant.id,
            now: Fixtures.now,
          ),
          isA<Ok<void>>(),
        );
        expect(
          _rule(
            ReservationPolicy.canRefund(
              reservation: paid,
              userId: Fixtures.participant.id,
              now: paid.eventStartsAt.add(const Duration(minutes: 1)),
            ),
          ),
          BusinessRule.eventAlreadyStarted,
        );
      },
    );
  });
}

BusinessRule? _rule(Result<void> result) => switch (result) {
  Err(failure: final BusinessRuleFailure f) => f.rule,
  _ => null,
};
