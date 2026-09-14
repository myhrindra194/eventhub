/// A post-event review: `reviews/{eventId}_{authorId}`.
///
/// Same deterministic-id trick as reservations: one review per person per
/// event is a property of the storage, and editing is an overwrite of the
/// same document.
class Review {
  const Review({
    required this.id,
    required this.eventId,
    required this.authorId,
    required this.authorName,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.updatedAt,
  });

  static String composeId({required String eventId, required String userId}) =>
      '${eventId}_$userId';

  final String id;
  final String eventId;
  final String authorId;
  final String authorName;

  /// 1..5.
  final int rating;
  final String comment;
  final DateTime createdAt;
  final DateTime? updatedAt;
}

/// Average and distribution of a set of reviews, for the event detail.
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

  /// Index 0 = one star, index 4 = five stars.
  final List<int> distribution;
}
