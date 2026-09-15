import 'package:eventhub/core/supabase/db.dart';
import 'package:eventhub/core/supabase/supabase_providers.dart';
import 'package:eventhub/features/reviews/data/review_dto.dart';
import 'package:eventhub/features/reviews/domain/review.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// `public.reviews`. RLS hides a hidden review from everyone but its author
/// and administrators, and lets a client write only its own review.
class ReviewRemoteDataSource {
  const ReviewRemoteDataSource(this._client);

  final SupabaseClient _client;

  /// The event detail shows the latest reviews, not an archive.
  static const maxPageSize = 100;

  Stream<List<Review>> watchEventReviews(String eventId) => _client
      .from(Tables.reviews)
      .stream(primaryKey: ['id'])
      .eq('event_id', eventId)
      .order('created_at')
      .limit(maxPageSize)
      .map(
        (rows) => rows
            .map(reviewFromRow)
            // The database already hides them from other people; the author
            // still receives their own hidden review, which belongs in the
            // "my review" card, not in the public list.
            .where((r) => !r.hidden)
            .toList(growable: false),
      )
      .resilient('event-reviews');

  /// The one review of [authorId] on [eventId] (unique per pair). Realtime
  /// takes a single filter: the author narrows the rows to a handful, the
  /// event is matched here.
  Stream<Review?> watchAuthorReview({
    required String eventId,
    required String authorId,
  }) => _client
      .from(Tables.reviews)
      .stream(primaryKey: ['id'])
      .eq('author_id', authorId)
      .map((rows) {
        for (final row in rows) {
          if (row['event_id'] == eventId) return reviewFromRow(row);
        }
        return null;
      })
      .resilient('my-review');

  Stream<Review?> watchById(String reviewId) => _client
      .from(Tables.reviews)
      .stream(primaryKey: ['id'])
      .eq('id', reviewId)
      .map((rows) => rows.isEmpty ? null : reviewFromRow(rows.first))
      .resilient('review');

  /// The only insertable columns. Author, name, organizer and dates are
  /// stamped by `reviews_before_insert`; RLS checks attendance.
  Future<void> create({
    required String eventId,
    required int rating,
    required String comment,
  }) => _client.from(Tables.reviews).insert({
    'event_id': eventId,
    'rating': rating,
    'comment': comment,
  });

  /// Only `rating` and `comment` are updatable; `updated_at` is stamped by
  /// the trigger.
  Future<void> update({
    required String eventId,
    required String authorId,
    required int rating,
    required String comment,
  }) => _client
      .from(Tables.reviews)
      .update({'rating': rating, 'comment': comment})
      .eq('event_id', eventId)
      .eq('author_id', authorId);

  Future<void> delete({required String eventId, required String authorId}) =>
      _client
          .from(Tables.reviews)
          .delete()
          .eq('event_id', eventId)
          .eq('author_id', authorId);

  static Review reviewFromRow(Map<String, dynamic> row) =>
      ReviewDto.fromJson(row).toDomain();
}
