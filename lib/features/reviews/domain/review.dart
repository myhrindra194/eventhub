/// A post-event review: a row of `public.reviews`.
///
/// One review per person per event is a UNIQUE constraint on
/// (event, author); the id itself is an opaque uuid, so the review of a
/// given person is looked up by that pair, never by composing an id.
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
    this.hidden = false,
  });

  final String id;
  final String eventId;

  /// Empty once the author's account is deleted (the review stays).
  final String authorId;
  final String authorName;

  /// 1..5.
  final int rating;
  final String comment;
  final DateTime createdAt;
  final DateTime? updatedAt;

  /// Set by moderation (automatic threshold or an admin), never by the
  /// author. A hidden review is left out of lists and averages; its author
  /// still sees it, with a notice.
  final bool hidden;
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
