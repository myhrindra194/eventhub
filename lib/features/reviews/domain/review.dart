/// A post-event review: `reviews/{eventId}_{authorId}`.
///
/// One review per person per event holds because the id is deterministic
/// (`DocIds.review`): there is only one document to write, and the rules
/// rebuild the same id to prove the author attended. Writing, editing or
/// removing a review moves the organizer's public rating in the same
/// transaction.
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

  /// The organizer whose rating this review counts in, copied from the
  /// event at creation.
  final String organizerId;

  /// Empty once the author's account is deleted (the review stays).
  final String authorId;
  final String authorName;

  /// 1..5.
  final int rating;
  final String comment;
  final DateTime createdAt;
  final DateTime? updatedAt;

  /// Set by moderation, never by the author. A hidden review is left out of
  /// lists and of the organizer's rating; its author still sees it, with a
  /// notice.
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
