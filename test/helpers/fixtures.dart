import 'package:eventhub/features/auth/domain/entities/app_user.dart';
import 'package:eventhub/features/auth/domain/entities/user_role.dart';
import 'package:eventhub/features/events/domain/entities/event.dart';
import 'package:eventhub/features/events/domain/entities/event_category.dart';
import 'package:eventhub/features/reservations/domain/entities/reservation.dart';

/// Deterministic fixtures for domain tests.
abstract final class Fixtures {
  static final now = DateTime(2026, 9, 8, 10);

  static const organizer = AppUser(
    id: 'org-1',
    name: 'Mirindra',
    email: 'mirindra@example.com',
    role: UserRole.organizer,
  );

  static const participant = AppUser(
    id: 'user-1',
    name: 'Elie',
    email: 'elie@example.com',
    role: UserRole.participant,
  );

  static Event event({
    String id = 'evt-1',
    int capacity = 100,
    int? availablePlaces,
    DateTime? startsAt,
    String organizerId = 'org-1',
  }) => Event(
    id: id,
    title: 'Flutter Meetup Madagascar',
    description: 'Rencontre de la communauté Flutter.',
    category: EventCategory.meetup,
    startsAt: startsAt ?? now.add(const Duration(days: 7)),
    location: 'Antananarivo',
    capacity: capacity,
    availablePlaces: availablePlaces ?? capacity,
    organizerId: organizerId,
    organizerName: 'Mirindra',
  );

  static Reservation reservation({
    String eventId = 'evt-1',
    String userId = 'user-1',
    ReservationStatus status = ReservationStatus.confirmed,
  }) => Reservation(
    id: Reservation.composeId(eventId: eventId, userId: userId),
    eventId: eventId,
    userId: userId,
    organizerId: 'org-1',
    userName: 'Elie',
    userEmail: 'elie@example.com',
    eventTitle: 'Flutter Meetup Madagascar',
    eventStartsAt: now.add(const Duration(days: 7)),
    eventLocation: 'Antananarivo',
    status: status,
    reservedAt: now,
  );
}
