import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/auth/domain/entities/app_user.dart';
import 'package:eventhub/features/reservations/domain/entities/reservation.dart';
import 'package:eventhub/features/reviews/domain/review.dart';

abstract interface class ReviewRepository {
  /// Most recent first, bounded (the rules cap a list at 100).
  Stream<List<Review>> watchEventReviews(String eventId);

  Stream<Review?> watchReview({
    required String eventId,
    required String userId,
  });

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
