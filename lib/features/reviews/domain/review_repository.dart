import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/auth/domain/entities/app_user.dart';
import 'package:eventhub/features/reservations/domain/entities/reservation.dart';
import 'package:eventhub/features/reviews/domain/review.dart';

abstract interface class ReviewRepository {
  /// Most recent first, bounded to the latest 100, hidden ones left out.
  Stream<List<Review>> watchEventReviews(String eventId);

  /// The review of [userId] on [eventId], hidden or not (its author still
  /// sees it).
  Stream<Review?> watchReview({
    required String eventId,
    required String userId,
  });

  /// A review by its id, for moderation: administrators see hidden reviews
  /// too.
  Stream<Review?> watchReviewById(String reviewId);

  /// Creates or edits the user's review after checking `ReviewPolicy`.
  AsyncResult<void> save({
    required AppUser user,
    required Reservation? reservation,
    required String eventId,
    required int rating,
    required String comment,
    required bool exists,
    required DateTime now,
  });

  AsyncResult<void> delete({required String eventId, required String userId});
}
