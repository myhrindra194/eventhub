import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventhub/core/firebase/firestore_paths.dart';
import 'package:eventhub/features/reviews/domain/review.dart';

/// `reviews/{eventId}_{authorId}`.
class ReviewRemoteDataSource {
  ReviewRemoteDataSource(FirebaseFirestore firestore)
    : _reviews = firestore.collection(FirestorePaths.reviews);

  final CollectionReference<Map<String, dynamic>> _reviews;

  /// Mirrors `request.query.limit <= 100` in the rules.
  static const maxPageSize = 100;

  Stream<List<Review>> watchEventReviews(String eventId) => _reviews
      .where('eventId', isEqualTo: eventId)
      .orderBy('createdAt', descending: true)
      .limit(maxPageSize)
      .snapshots()
      .map(
        (s) => s.docs
            .map((d) => reviewFromFirestore(d.id, d.data()))
            .toList(growable: false),
      );

  Stream<Review?> watchReview(String id) =>
      _reviews.doc(id).snapshots().map((s) {
        final data = s.data();
        return data == null ? null : reviewFromFirestore(s.id, data);
      });

  /// Field set accepted by the `create` rule.
  Future<void> create({
    required String id,
    required String eventId,
    required String authorId,
    required String authorName,
    required int rating,
    required String comment,
  }) => _reviews.doc(id).set({
    'eventId': eventId,
    'authorId': authorId,
    'authorName': authorName,
    'rating': rating,
    'comment': comment,
    'createdAt': FieldValue.serverTimestamp(),
  });

  /// Only `rating`, `comment` and `updatedAt` may change.
  Future<void> update({
    required String id,
    required int rating,
    required String comment,
  }) => _reviews.doc(id).update({
    'rating': rating,
    'comment': comment,
    'updatedAt': FieldValue.serverTimestamp(),
  });

  Future<void> delete(String id) => _reviews.doc(id).delete();

  static Review reviewFromFirestore(String id, Map<String, dynamic> data) {
    DateTime? time(String key) => switch (data[key]) {
      final Timestamp t => t.toDate(),
      _ => null,
    };
    return Review(
      id: id,
      eventId: data['eventId'] as String? ?? '',
      authorId: data['authorId'] as String? ?? '',
      authorName: data['authorName'] as String? ?? '',
      rating: (data['rating'] as num?)?.toInt() ?? 0,
      comment: data['comment'] as String? ?? '',
      createdAt: time('createdAt') ?? DateTime.now(),
      updatedAt: time('updatedAt'),
    );
  }
}
