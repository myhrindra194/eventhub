import 'package:eventhub/features/events/domain/entities/event.dart';
import 'package:eventhub/features/events/domain/entities/event_category.dart';

/// Why an event is suggested — shown to the user, so it must be true.
enum RecommendationReason { followedOrganizer, sameCategory }

class Recommendation {
  const Recommendation({
    required this.event,
    required this.reason,
    required this.score,
  });

  final Event event;
  final RecommendationReason reason;
  final double score;
}

/// "Pour vous" (F-18): a transparent heuristic, computed on the device from
/// what the user already did — no profiling server, nothing sent anywhere.
///
/// Signals, strongest first:
///  * the event is by an organizer the user follows (+4);
///  * its category matches events the user booked (+3 each) or starred
///    (+2 each), looked up in the loaded catalogue;
///  * a small tie-breaker on how full it is (0..1): popular events first.
///
/// An event with no personal signal is never suggested — the other rails
/// already cover "popular". Events that started, are sold out, already
/// booked or already starred are excluded: suggesting what the user has is
/// noise.
abstract final class Recommender {
  static const maxResults = 10;
  static const followWeight = 4.0;
  static const bookingWeight = 3.0;
  static const favoriteWeight = 2.0;

  static List<Recommendation> rank({
    required List<Event> catalogue,
    required Set<String> favoriteIds,
    required Set<String> bookedEventIds,
    required Set<String> followedOrganizerIds,
    required DateTime now,
    int limit = maxResults,
  }) {
    final byId = {for (final e in catalogue) e.id: e};
    final affinity = <EventCategory, double>{};
    void learn(String eventId, double weight) {
      final category = byId[eventId]?.category;
      if (category == null) return;
      affinity.update(category, (v) => v + weight, ifAbsent: () => weight);
    }

    for (final id in favoriteIds) {
      learn(id, favoriteWeight);
    }
    for (final id in bookedEventIds) {
      learn(id, bookingWeight);
    }

    final results = <Recommendation>[];
    for (final event in catalogue) {
      if (event.hasStarted(now) ||
          event.isFull ||
          favoriteIds.contains(event.id) ||
          bookedEventIds.contains(event.id)) {
        continue;
      }
      final followed = followedOrganizerIds.contains(event.organizerId);
      final categoryScore = affinity[event.category] ?? 0;
      if (!followed && categoryScore == 0) continue;

      results.add(
        Recommendation(
          event: event,
          reason: followed
              ? RecommendationReason.followedOrganizer
              : RecommendationReason.sameCategory,
          score: (followed ? followWeight : 0) + categoryScore + event.fillRate,
        ),
      );
    }

    results.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      return byScore != 0
          ? byScore
          : a.event.startsAt.compareTo(b.event.startsAt);
    });
    return results.take(limit).toList(growable: false);
  }
}
