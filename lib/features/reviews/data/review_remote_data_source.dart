import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventhub/core/firebase/firebase_providers.dart';
import 'package:eventhub/core/firebase/firestore_paths.dart';
import 'package:eventhub/features/auth/domain/entities/app_user.dart';
import 'package:eventhub/features/reviews/data/review_dto.dart';
import 'package:eventhub/features/reviews/domain/review.dart';

/// `reviews/{eventId}_{authorId}` and the rating it feeds on
/// `organizers/{organizerId}` (`ratingSum`, `ratingCount`, `lastReviewId`).
///
/// The rules accept a rating change only in the commit that writes the
/// review justifying it, by exactly the visible difference. Each write below
/// is therefore a transaction that first reads the review: the step is
/// computed from the stored rating and hidden flag, not from what a possibly
/// stale screen showed, and a concurrent edit makes the transaction retry
/// instead of being refused.
class ReviewRemoteDataSource {
  const ReviewRemoteDataSource(this._db);

  final FirebaseFirestore _db;

  /// The event detail shows the latest reviews, not an archive.
  static const maxPageSize = 100;

  CollectionReference<Map<String, dynamic>> get _reviews =>
      _db.collection(Collections.reviews);

  DocumentReference<Map<String, dynamic>> _organizer(String organizerId) =>
      _db.collection(Collections.organizers).doc(organizerId);

  /// Most recent first. `hidden == false` is part of the query because the
  /// rules refuse a list that could return a hidden review of someone else.
  Stream<List<Review>> watchEventReviews(String eventId) => _reviews
      .where('eventId', isEqualTo: eventId)
      .where('hidden', isEqualTo: false)
      .orderBy('createdAt', descending: true)
      .limit(maxPageSize)
      .snapshots()
      .map(
        (query) => query.docs
            .map((d) => ReviewDto.fromJson(d.data()).toDomain(d.id))
            .toList(growable: false),
      )
      .resilient('event-reviews');

  /// The author's review, hidden or not: a missing document is readable.
  Stream<Review?> watchReview({
    required String eventId,
    required String authorId,
  }) => watchById(DocIds.review(eventId, authorId));

  Stream<Review?> watchById(String reviewId) => _reviews
      .doc(reviewId)
      .snapshots()
      .map((s) {
        final data = s.data();
        return data == null ? null : ReviewDto.fromJson(data).toDomain(s.id);
      })
      .resilient('review:$reviewId');

  /// Creates the review of [author], or edits it when it already exists (a
  /// second device, a stream not caught up): what the person meant either
  /// way.
  ///
  /// [organizerId] is the event's, as copied on the author's reservation —
  /// the rules compare it with the event.
  Future<void> save({
    required String eventId,
    required String organizerId,
    required AppUser author,
    required int rating,
    required String comment,
  }) => _db.runTransaction((tx) async {
    final ref = _reviews.doc(DocIds.review(eventId, author.id));
    final current = (await tx.get(ref)).data();

    if (current == null) {
      tx
        ..set(ref, {
          'eventId': eventId,
          'organizerId': organizerId,
          'authorId': author.id,
          'authorName': author.name,
          'rating': rating,
          'comment': comment,
          'hidden': false,
          'createdAt': FieldValue.serverTimestamp(),
        })
        ..update(_organizer(organizerId), {
          'ratingSum': FieldValue.increment(rating),
          'ratingCount': FieldValue.increment(1),
          'lastReviewId': ref.id,
        });
      return;
    }

    final previous = (current['rating'] as num?)?.toInt() ?? 0;
    tx.update(ref, {
      'rating': rating,
      'comment': comment,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    // A hidden review counts for nothing: editing it moves no rating. An
    // unchanged note moves nothing either, and needs no organizer write.
    if (current['hidden'] != true && rating != previous) {
      tx.update(_organizer(current['organizerId'] as String), {
        'ratingSum': FieldValue.increment(rating - previous),
        'lastReviewId': ref.id,
      });
    }
  });

  /// Removes [authorId]'s review and, unless moderation had hidden it, its
  /// share of the rating. A no-op when there is none.
  Future<void> delete({required String eventId, required String authorId}) =>
      _db.runTransaction((tx) async {
        final ref = _reviews.doc(DocIds.review(eventId, authorId));
        final current = (await tx.get(ref)).data();
        if (current == null) return;
        tx.delete(ref);
        if (current['hidden'] != true) {
          tx.update(_organizer(current['organizerId'] as String), {
            'ratingSum': FieldValue.increment(
              -((current['rating'] as num?)?.toInt() ?? 0),
            ),
            'ratingCount': FieldValue.increment(-1),
            'lastReviewId': ref.id,
          });
        }
      });
}
