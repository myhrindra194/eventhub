import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/errors/failure_exception.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/auth/domain/entities/app_user.dart';
import 'package:eventhub/features/events/domain/entities/event.dart';
import 'package:eventhub/features/reservations/data/datasources/reservation_remote_data_source.dart';
import 'package:eventhub/features/reservations/data/repositories/reservation_repository_impl.dart';
import 'package:eventhub/features/reservations/domain/entities/reservation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fixtures.dart';

class _MockRemote extends Mock implements ReservationRemoteDataSource {}

/// Joue le rôle de la transaction : remet au contrôle de la source de données
/// ce qu'elle est censée avoir « lu », et lève son refus exactement comme le
/// ferait la vraie source.
void _stubReserve(
  _MockRemote remote, {
  required Event event,
  Reservation? existing,
}) {
  when(
    () => remote.reserve(
      eventId: any(named: 'eventId'),
      participant: any(named: 'participant'),
      tierId: any(named: 'tierId'),
      check: any(named: 'check'),
    ),
  ).thenAnswer((invocation) async {
    final check = invocation.namedArguments[#check] as BookingCheck;
    return switch (check(event, existing)) {
      Ok() => Fixtures.reservation(eventId: event.id),
      Err(:final failure) => throw FailureException(failure),
    };
  });
}

void main() {
  late _MockRemote remote;
  late ReservationRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(Fixtures.participant);
    Result<void> acceptBooking(Event _, Reservation? _) => const Ok(null);
    Result<void> acceptCancellation(Reservation _) => const Ok(null);
    registerFallbackValue(acceptBooking);
    registerFallbackValue(acceptCancellation);
  });

  setUp(() {
    remote = _MockRemote();
    repository = ReservationRepositoryImpl(remote, clock: () => Fixtures.now);
  });

  BusinessRule? rule(Result<Object?> r) => switch (r) {
    Err(failure: final BusinessRuleFailure f) => f.rule,
    _ => null,
  };

  group('reserve', () {
    test('books when the policy accepts what the transaction read', () async {
      _stubReserve(remote, event: Fixtures.event());
      final result = await repository.reserve(
        eventId: 'evt-1',
        participant: Fixtures.participant,
      );
      expect(result, isA<Ok<Reservation>>());
    });

    test('refuses on fresh reads: the last seat just went', () async {
      _stubReserve(remote, event: Fixtures.event(availablePlaces: 0));
      final result = await repository.reserve(
        eventId: 'evt-1',
        participant: Fixtures.participant,
      );
      expect(rule(result), BusinessRule.eventFull);
    });

    test('an organizer account books another organizer\'s event', () async {
      _stubReserve(remote, event: Fixtures.event(organizerId: 'someone'));
      final result = await repository.reserve(
        eventId: 'evt-1',
        participant: Fixtures.organizer,
      );
      expect(result, isA<Ok<Reservation>>());
    });

    test('the team of the event is refused with a sentence', () async {
      _stubReserve(remote, event: Fixtures.event());
      final result = await repository.reserve(
        eventId: 'evt-1',
        participant: Fixtures.organizer,
      );
      expect(result.failureOrNull, isA<PermissionFailure>());
    });

    test('a paid type is not bookable without a payment server', () async {
      final result = await repository.startCheckout(
        eventId: 'evt-1',
        tierId: 'vip',
      );
      expect(rule(result), BusinessRule.paymentRequired);
      expect(
        rule(await repository.cancelPendingCheckout(eventId: 'evt-1')),
        BusinessRule.paymentRequired,
      );
      expect(
        rule(await repository.refund(eventId: 'evt-1')),
        BusinessRule.paymentRequired,
      );
      verifyZeroInteractions(remote);
    });
  });

  group('cancel', () {
    void stubCancel(Reservation stored) {
      when(
        () => remote.cancel(
          reservationId: any(named: 'reservationId'),
          userId: any(named: 'userId'),
          check: any(named: 'check'),
        ),
      ).thenAnswer((invocation) async {
        final check = invocation.namedArguments[#check] as CancellationCheck;
        return switch (check(stored)) {
          Ok() => stored.copyWith(status: ReservationStatus.cancelled),
          Err(:final failure) => throw FailureException(failure),
        };
      });
    }

    test('the holder cancels their own seat', () async {
      stubCancel(Fixtures.reservation());
      final result = await repository.cancel(
        reservationId: 'evt-1_user-1',
        userId: Fixtures.participant.id,
      );
      expect(result.valueOrNull?.isCancelled, isTrue);
    });

    test('nobody cancels somebody else\'s seat', () async {
      stubCancel(Fixtures.reservation());
      final result = await repository.cancel(
        reservationId: 'evt-1_user-1',
        userId: 'intruder',
      );
      expect(rule(result), BusinessRule.notReservationOwner);
    });

    test('a seat already given back is not cancelled twice', () async {
      stubCancel(Fixtures.reservation(status: ReservationStatus.cancelled));
      final result = await repository.cancel(
        reservationId: 'evt-1_user-1',
        userId: Fixtures.participant.id,
      );
      expect(rule(result), BusinessRule.reservationNotActive);
    });
  });

  test('reads a person\'s seat by its deterministic id', () {
    final seat = Fixtures.reservation();
    when(
      () => remote.watchForEvent(eventId: 'evt-1', userId: 'user-1'),
    ).thenAnswer((_) => Stream.value(seat));
    expect(
      repository.watchForEvent(eventId: 'evt-1', userId: 'user-1'),
      emits(seat),
    );
  });

  test('participant fixture is a plain account', () {
    const AppUser user = Fixtures.participant;
    expect(user.isParticipant, isTrue);
  });
}
