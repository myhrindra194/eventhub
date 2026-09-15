import 'package:eventhub/features/events/domain/entities/event.dart';
import 'package:eventhub/features/events/domain/entities/event_category.dart';
import 'package:eventhub/features/organizer/domain/organizer_insights.dart';
import 'package:eventhub/features/reservations/domain/entities/reservation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 9, 14, 12);

  Event event(
    String id, {
    required DateTime startsAt,
    int capacity = 10,
    int available = 10,
  }) => Event(
    id: id,
    title: 'Event $id',
    description: 'd',
    category: EventCategory.meetup,
    startsAt: startsAt,
    location: 'Antananarivo',
    capacity: capacity,
    availablePlaces: available,
    organizerId: 'o1',
    organizerName: 'Mirindra',
  );

  Reservation reservation(
    String eventId,
    String userId, {
    required DateTime reservedAt,
    DateTime? cancelledAt,
  }) => Reservation(
    id: 'res-$eventId-$userId',
    eventId: eventId,
    userId: userId,
    organizerId: 'o1',
    userName: 'Guest $userId',
    userEmail: '$userId@example.com',
    eventTitle: 'Event $eventId',
    eventStartsAt: now.add(const Duration(days: 3)),
    eventLocation: 'Antananarivo',
    status: cancelledAt == null
        ? ReservationStatus.confirmed
        : ReservationStatus.cancelled,
    reservedAt: reservedAt,
    cancelledAt: cancelledAt,
  );

  group('OrganizerStats.compute', () {
    test('takes seat counts from the events', () {
      final stats = OrganizerStats.compute(
        events: [
          event('a', startsAt: now.add(const Duration(days: 2)), available: 4),
          event('b', startsAt: now.add(const Duration(days: 5)), available: 0),
          event('c', startsAt: now.subtract(const Duration(days: 1))),
        ],
        reservations: const [],
        now: now,
      );

      expect(stats.booked, 16);
      expect(stats.capacity, 30);
      expect(stats.fillRate, closeTo(16 / 30, 1e-9));
      expect(stats.upcomingCount, 2);
      expect(stats.soldOutCount, 1);
    });

    test('buckets bookings by calendar day, today last, window only', () {
      final stats = OrganizerStats.compute(
        events: const [],
        reservations: [
          reservation('a', 'u1', reservedAt: now),
          reservation('a', 'u2', reservedAt: DateTime(2026, 9, 14, 0, 5)),
          reservation('a', 'u3', reservedAt: DateTime(2026, 9, 13, 23, 50)),
          reservation(
            'a',
            'u4',
            reservedAt: now.subtract(const Duration(days: 13)),
          ),
          reservation(
            'a',
            'u5',
            reservedAt: now.subtract(const Duration(days: 14)),
          ),
        ],
        now: now,
      );

      expect(stats.dailyBookings, hasLength(OrganizerStats.window));
      expect(stats.dailyBookings.last, 2);
      expect(stats.dailyBookings[OrganizerStats.window - 2], 1);
      expect(stats.dailyBookings.first, 1);
      expect(stats.dailyBookings.reduce((a, b) => a + b), 4);
      expect(stats.bookingsLast7Days, 3);
    });

    test('counts cancellations and ranks upcoming events by fill rate', () {
      final soon = now.add(const Duration(days: 2));
      final stats = OrganizerStats.compute(
        events: [
          event('low', startsAt: soon, available: 9),
          event('high', startsAt: soon, available: 1),
          event(
            'past',
            startsAt: now.subtract(const Duration(days: 2)),
            available: 0,
          ),
        ],
        reservations: [
          reservation('high', 'u1', reservedAt: now, cancelledAt: now),
        ],
        now: now,
      );

      expect(stats.cancellations, 1);
      expect(stats.cancellationRate, closeTo(1 / (20 + 1), 1e-9));
      expect(stats.ranking.map((p) => p.event.id), ['high', 'low']);
      expect(stats.ranking.first.cancellations, 1);
    });
  });

  group('OrganizerAlerts.watchlist', () {
    test('flags starting soon, last seats and sold out, soonest first', () {
      final alerts = OrganizerAlerts.watchlist(
        events: [
          event(
            'full',
            startsAt: now.add(const Duration(days: 4)),
            available: 0,
          ),
          event(
            'tight',
            startsAt: now.add(const Duration(hours: 20)),
            available: 2,
          ),
          event('calm', startsAt: now.add(const Duration(days: 6))),
          event(
            'over',
            startsAt: now.subtract(const Duration(hours: 1)),
            available: 0,
          ),
        ],
        now: now,
      );

      expect(alerts.map((a) => (a.eventId, a.kind)), [
        ('tight', AlertKind.startingSoon),
        ('tight', AlertKind.lastSeats),
        ('full', AlertKind.soldOut),
      ]);
      expect(alerts[1].seatsLeft, 2);
    });
  });

  group('OrganizerAlerts.activity', () {
    test('emits booking and cancellation, most recent first, bounded', () {
      final items = OrganizerAlerts.activity(
        reservations: [
          reservation(
            'a',
            'u1',
            reservedAt: now.subtract(const Duration(days: 2)),
            cancelledAt: now.subtract(const Duration(hours: 1)),
          ),
          reservation(
            'a',
            'u2',
            reservedAt: now.subtract(const Duration(hours: 5)),
          ),
        ],
      );

      expect(items.map((a) => (a.kind, a.personName)), [
        (AlertKind.cancellation, 'Guest u1'),
        (AlertKind.booking, 'Guest u2'),
        (AlertKind.booking, 'Guest u1'),
      ]);

      final bounded = OrganizerAlerts.activity(
        reservations: [
          for (var i = 0; i < 10; i++)
            reservation(
              'a',
              'u$i',
              reservedAt: now.subtract(Duration(hours: i)),
            ),
        ],
        limit: 4,
      );
      expect(bounded, hasLength(4));
    });
  });
}
