import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/auth/domain/entities/app_user.dart';
import 'package:eventhub/features/auth/domain/entities/user_role.dart';
import 'package:eventhub/features/events/domain/entities/event.dart';
import 'package:eventhub/features/events/domain/entities/event_category.dart';
import 'package:eventhub/features/reservations/domain/entities/reservation.dart';
import 'package:eventhub/features/waitlist/domain/waitlist_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 9, 14, 12);
  const participant = AppUser(
    id: 'u1',
    name: 'Jean',
    email: 'jean@example.com',
    role: UserRole.participant,
  );

  Event event({int available = 0, DateTime? startsAt}) => Event(
    id: 'e1',
    title: 'Pulse Festival',
    description: 'd',
    category: EventCategory.concert,
    startsAt: startsAt ?? now.add(const Duration(days: 3)),
    location: 'Stade',
    capacity: 100,
    availablePlaces: available,
    organizerId: 'o1',
    organizerName: 'Elie',
  );

  Result<void> canJoin({
    Event? e,
    AppUser user = participant,
    Reservation? reservation,
  }) => WaitlistPolicy.canJoin(
    event: e ?? event(),
    user: user,
    reservation: reservation,
    now: now,
  );

  BusinessRule? rule(Result<void> r) => switch (r) {
    Err(failure: final BusinessRuleFailure f) => f.rule,
    _ => null,
  };

  test('a participant can wait for a sold-out upcoming event', () {
    expect(canJoin(), isA<Ok<void>>());
  });

  test('refuses when seats are available', () {
    expect(
      rule(canJoin(e: event(available: 3))),
      BusinessRule.waitlistNotAvailable,
    );
  });

  test('refuses once the event has started', () {
    expect(
      rule(
        canJoin(e: event(startsAt: now.subtract(const Duration(minutes: 1)))),
      ),
      BusinessRule.eventAlreadyStarted,
    );
  });

  test('refuses someone who already holds a seat, and organizers', () {
    final seat = Reservation(
      id: 'e1_u1',
      eventId: 'e1',
      userId: 'u1',
      organizerId: 'o1',
      userName: 'Jean',
      userEmail: 'jean@example.com',
      eventTitle: 'Pulse Festival',
      eventStartsAt: now.add(const Duration(days: 3)),
      eventLocation: 'Stade',
      status: ReservationStatus.confirmed,
      reservedAt: now,
    );
    expect(rule(canJoin(reservation: seat)), BusinessRule.alreadyReserved);
    expect(
      canJoin(user: participant.copyWith(role: UserRole.organizer)),
      isA<Err<void>>(),
    );
  });
}
