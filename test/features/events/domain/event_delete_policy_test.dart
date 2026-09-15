import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/auth/domain/entities/app_user.dart';
import 'package:eventhub/features/auth/domain/entities/user_role.dart';
import 'package:eventhub/features/events/domain/entities/event.dart';
import 'package:eventhub/features/events/domain/entities/event_category.dart';
import 'package:eventhub/features/events/domain/policies/event_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const owner = AppUser(
    id: 'o1',
    name: 'Mirindra',
    email: 'o1@example.com',
    role: UserRole.organizer,
  );

  Event event({int available = 10}) => Event(
    id: 'e1',
    title: 'Flutter Meetup',
    description: 'd',
    category: EventCategory.meetup,
    startsAt: DateTime(2030),
    location: 'Antananarivo',
    capacity: 10,
    availablePlaces: available,
    organizerId: 'o1',
    organizerName: 'Mirindra',
  );

  BusinessRule? rule(Result<void> result) => switch (result) {
    Err(failure: final BusinessRuleFailure f) => f.rule,
    _ => null,
  };

  test('allows the owner to delete an event nobody booked', () {
    expect(EventPolicy.canDelete(event: event(), user: owner), isA<Ok<void>>());
  });

  test('refuses deleting an event with seats taken, like the rules', () {
    final result = EventPolicy.canDelete(
      event: event(available: 8),
      user: owner,
    );
    expect(rule(result), BusinessRule.eventHasReservations);
  });

  test('checks ownership first', () {
    const other = AppUser(
      id: 'o2',
      name: 'Autre',
      email: 'o2@example.com',
      role: UserRole.organizer,
    );
    expect(
      rule(EventPolicy.canDelete(event: event(available: 8), user: other)),
      BusinessRule.notEventOwner,
    );
  });
}
