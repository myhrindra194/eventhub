import 'package:eventhub/features/events/domain/entities/event.dart';
import 'package:eventhub/features/events/domain/entities/event_category.dart';

/// Pourquoi un événement est suggéré — le motif est montré à
/// l’utilisateur, il doit donc être vrai.
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

/// « Pour vous » (F-18) : une heuristique transparente, calculée sur
/// l’appareil à partir de ce que l’utilisateur a déjà fait — aucun serveur
/// de profilage, rien n’est envoyé nulle part.
///
/// Signaux, du plus fort au plus faible :
///  * l’événement est d’un organisateur que l’utilisateur suit (+4) ;
///  * sa catégorie recoupe celle des événements qu’il a réservés (+3
///    chacun) ou mis en favori (+2 chacun), retrouvés dans le catalogue
///    chargé ;
///  * un léger départage sur le taux de remplissage (0..1) : les
///    événements populaires d’abord.
///
/// Un événement sans aucun signal personnel n’est jamais suggéré — les
/// autres rails couvrent déjà « populaire ». Les événements commencés,
/// complets, déjà réservés ou déjà en favori sont exclus : suggérer à
/// l’utilisateur ce qu’il a déjà, c’est du bruit.
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
