import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/result/result.dart';
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

    test('checks "already reserved" before "full"', () {
      // A participant holding the last seat must get the precise message.
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

  test('composeId is deterministic per (event, user)', () {
    expect(
      Reservation.composeId(eventId: 'e', userId: 'u'),
      Reservation.composeId(eventId: 'e', userId: 'u'),
    );
    expect(Reservation.composeId(eventId: 'e', userId: 'u'), 'e_u');
  });
}

BusinessRule? _rule(Result<void> result) => switch (result) {
  Err(failure: final BusinessRuleFailure f) => f.rule,
  _ => null,
};
