import 'package:eventhub/core/errors/failure_exception.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/auth/domain/entities/app_user.dart';
import 'package:eventhub/features/reservations/domain/entities/reservation.dart';
import 'package:eventhub/features/reviews/data/review_remote_data_source.dart';
import 'package:eventhub/features/reviews/domain/review.dart';
import 'package:eventhub/features/reviews/domain/review_policy.dart';
import 'package:eventhub/features/reviews/domain/review_repository.dart';

class ReviewRepositoryImpl implements ReviewRepository {
  const ReviewRepositoryImpl(this._remote);

  final ReviewRemoteDataSource _remote;

  @override
  Stream<List<Review>> watchEventReviews(String eventId) =>
      _remote.watchEventReviews(eventId);

  @override
  Stream<Review?> watchReview({
    required String eventId,
    required String userId,
  }) => _remote.watchReview(Review.composeId(eventId: eventId, userId: userId));

  @override
  AsyncResult<void> save({
    required AppUser user,
    required Reservation? reservation,
    required String eventId,
    required int rating,
    required String comment,
    required bool exists,
    required DateTime now,
  }) {
    return guard(() async {
      if (ReviewPolicy.canReview(user: user, reservation: reservation, now: now)
          case Err(:final failure)) {
        throw FailureException(failure);
      }
      if (ReviewPolicy.validate(rating: rating, comment: comment) case Err(
        :final failure,
      )) {
        throw FailureException(failure);
      }
      final id = Review.composeId(eventId: eventId, userId: user.id);
      final text = comment.trim();
      if (exists) {
        await _remote.update(id: id, rating: rating, comment: text);
      } else {
        await _remote.create(
          id: id,
          eventId: eventId,
          authorId: user.id,
          authorName: user.name,
          rating: rating,
          comment: text,
        );
      }
    });
  }

  @override
  AsyncResult<void> delete({required String eventId, required String userId}) =>
      guard(
        () =>
            _remote.delete(Review.composeId(eventId: eventId, userId: userId)),
      );
}
