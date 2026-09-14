import 'package:eventhub/features/events/domain/entities/event.dart';
import 'package:eventhub/features/reservations/domain/entities/reservation.dart';

/// Organizer analytics, derived from data the app already streams.
///
/// Pure functions over `Event` and `Reservation` lists: no Firestore
/// aggregate, no Cloud Function, no extra read. The cost is a known limit —
/// everything is computed from at most `maxPageSize` reservations, and a
/// reservation cancelled then re-booked is one document, so its cancellation
/// is no longer visible. Both are acceptable at MVP scale and are the reason
/// a server-side aggregate (`aggregates/`, ROADMAP F-07) exists on paper.

/// What happened, or what deserves attention.
enum AlertKind {
  /// Someone booked a seat.
  booking,

  /// Someone gave their seat back.
  cancellation,

  /// An upcoming event has no seat left.
  soldOut,

  /// An upcoming event is down to its last seats.
  lastSeats,

  /// An event starts within [OrganizerAlerts.startingSoonWindow].
  startingSoon,
}

class OrganizerAlert {
  const OrganizerAlert({
    required this.kind,
    required this.at,
    required this.eventId,
    required this.eventTitle,
    this.personName,
    this.seatsLeft,
  });

  final AlertKind kind;

  /// When it happened — or, for an event-state alert, when the event starts.
  final DateTime at;
  final String eventId;
  final String eventTitle;

  /// Set on [AlertKind.booking] and [AlertKind.cancellation].
  final String? personName;

  /// Set on event-state alerts.
  final int? seatsLeft;
}

abstract final class OrganizerAlerts {
  /// Same threshold as the "dernières places" state of the event detail.
  static const lastSeatsThreshold = 3;
  static const startingSoonWindow = Duration(hours: 24);

  /// Upcoming events that need a look, soonest first. An event can appear
  /// twice (starting soon *and* nearly full): those are two different
  /// reasons to open it.
  static List<OrganizerAlert> watchlist({
    required List<Event> events,
    required DateTime now,
  }) {
    final upcoming = events.where((e) => !e.hasStarted(now)).toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));

    OrganizerAlert about(Event e, AlertKind kind) => OrganizerAlert(
      kind: kind,
      at: e.startsAt,
      eventId: e.id,
      eventTitle: e.title,
      seatsLeft: e.availablePlaces,
    );

    return [
      for (final e in upcoming) ...[
        if (e.startsAt.difference(now) <= startingSoonWindow)
          about(e, AlertKind.startingSoon),
        if (e.isFull)
          about(e, AlertKind.soldOut)
        else if (e.availablePlaces <= lastSeatsThreshold)
          about(e, AlertKind.lastSeats),
      ],
    ];
  }

  /// Bookings and cancellations, most recent first. A cancelled reservation
  /// yields both events — the booking did happen.
  static List<OrganizerAlert> activity({
    required List<Reservation> reservations,
    int limit = 60,
  }) {
    final items = <OrganizerAlert>[
      for (final r in reservations) ...[
        OrganizerAlert(
          kind: AlertKind.booking,
          at: r.reservedAt,
          eventId: r.eventId,
          eventTitle: r.eventTitle,
          personName: r.userName,
        ),
        if (r.isCancelled && r.cancelledAt != null)
          OrganizerAlert(
            kind: AlertKind.cancellation,
            at: r.cancelledAt!,
            eventId: r.eventId,
            eventTitle: r.eventTitle,
            personName: r.userName,
          ),
      ],
    ]..sort((a, b) => b.at.compareTo(a.at));
    return List.unmodifiable(items.take(limit));
  }
}

class EventPerformance {
  const EventPerformance({required this.event, required this.cancellations});

  final Event event;
  final int cancellations;
}

class OrganizerStats {
  const OrganizerStats({
    required this.eventCount,
    required this.upcomingCount,
    required this.soldOutCount,
    required this.booked,
    required this.capacity,
    required this.cancellations,
    required this.dailyBookings,
    required this.ranking,
  });

  /// Computes the statistics at [now].
  ///
  /// Seat counts come from the events (`capacity - availablePlaces`, the
  /// transactional source of truth); the timeline and cancellations come
  /// from the reservation documents.
  factory OrganizerStats.compute({
    required List<Event> events,
    required List<Reservation> reservations,
    required DateTime now,
  }) {
    final daily = List<int>.filled(window, 0);
    final cancelledByEvent = <String, int>{};
    var cancellations = 0;
    final today = _dayNumber(now);

    for (final r in reservations) {
      if (r.isCancelled) {
        cancellations++;
        cancelledByEvent.update(r.eventId, (v) => v + 1, ifAbsent: () => 1);
      }
      final offset = today - _dayNumber(r.reservedAt);
      if (offset >= 0 && offset < window) daily[window - 1 - offset]++;
    }

    final upcoming = events.where((e) => !e.hasStarted(now)).toList();
    final ranking = [
      for (final e in upcoming)
        EventPerformance(event: e, cancellations: cancelledByEvent[e.id] ?? 0),
    ]..sort((a, b) => b.event.fillRate.compareTo(a.event.fillRate));

    return OrganizerStats(
      eventCount: events.length,
      upcomingCount: upcoming.length,
      soldOutCount: upcoming.where((e) => e.isFull).length,
      booked: events.fold(0, (sum, e) => sum + e.reservedCount),
      capacity: events.fold(0, (sum, e) => sum + e.capacity),
      cancellations: cancellations,
      dailyBookings: List.unmodifiable(daily),
      ranking: List.unmodifiable(ranking),
    );
  }

  /// Length of [dailyBookings], in days.
  static const window = 14;

  final int eventCount;
  final int upcomingCount;
  final int soldOutCount;

  /// Seats taken, across every event.
  final int booked;
  final int capacity;
  final int cancellations;

  /// Bookings per calendar day, oldest first; the last entry is today.
  final List<int> dailyBookings;

  /// Upcoming events, fullest first.
  final List<EventPerformance> ranking;

  double get fillRate => capacity == 0 ? 0 : booked / capacity;

  double get cancellationRate {
    final total = booked + cancellations;
    return total == 0 ? 0 : cancellations / total;
  }

  int get bookingsLast7Days =>
      dailyBookings.skip(window - 7).fold(0, (sum, v) => sum + v);

  /// Calendar day number, immune to daylight-saving shifts (a local
  /// `difference().inDays` across a DST change is off by one).
  static int _dayNumber(DateTime d) =>
      DateTime.utc(d.year, d.month, d.day).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;
}
