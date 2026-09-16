/// Un avis publié après l’événement : `reviews/{eventId}_{authorId}`.
///
/// La règle « un avis par personne et par événement » tient parce que l’id
/// est déterministe (`DocIds.review`) : il n’y a qu’un seul document à
/// écrire, et les règles reconstruisent ce même id pour prouver que l’auteur
/// a bien participé. Écrire, modifier ou supprimer un avis déplace la note
/// publique de l’organisateur dans la même transaction.
class Review {
  const Review({
    required this.id,
    required this.eventId,
    required this.authorId,
    required this.authorName,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.organizerId = '',
    this.updatedAt,
    this.hidden = false,
  });

  final String id;
  final String eventId;

  /// L’organisateur dans la note duquel cet avis compte, copié depuis
  /// l’événement à la création.
  final String organizerId;

  /// Vide une fois le compte de l’auteur supprimé (l’avis demeure).
  final String authorId;
  final String authorName;

  /// 1..5.
  final int rating;
  final String comment;
  final DateTime createdAt;
  final DateTime? updatedAt;

  /// Posé par la modération, jamais par l’auteur. Un avis masqué est écarté
  /// des listes et de la note de l’organisateur ; son auteur continue de le
  /// voir, accompagné d’un avertissement.
  final bool hidden;
}

/// Moyenne et distribution d’un ensemble d’avis, pour le détail de
/// l’événement.
class ReviewSummary {
  const ReviewSummary({
    required this.count,
    required this.average,
    required this.distribution,
  });

  factory ReviewSummary.of(Iterable<Review> reviews) {
    final distribution = List<int>.filled(5, 0);
    var total = 0;
    var count = 0;
    for (final r in reviews) {
      if (r.rating < 1 || r.rating > 5) continue;
      distribution[r.rating - 1]++;
      total += r.rating;
      count++;
    }
    return ReviewSummary(
      count: count,
      average: count == 0 ? 0 : total / count,
      distribution: List.unmodifiable(distribution),
    );
  }

  final int count;
  final double average;

  /// Index 0 = une étoile, index 4 = cinq étoiles.
  final List<int> distribution;
}
