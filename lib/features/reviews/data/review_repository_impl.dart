import 'package:cloud_firestore/cloud_firestore.dart' show FirebaseException;
import 'package:eventhub/core/errors/failure.dart';
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
  }) => _remote.watchReview(eventId: eventId, authorId: userId);

  @override
  Stream<Review?> watchReviewById(String reviewId) =>
      _remote.watchById(reviewId);

  @override
  AsyncResult<void> save({
    required AppUser user,
    required Reservation? reservation,
    required String eventId,
    required int rating,
    required String comment,
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
      try {
        await _remote.save(
          eventId: eventId,
          // canReview proved the reservation exists; it carries the event's
          // organizer exactly as the rules expect it.
          organizerId: reservation!.organizerId,
          author: user,
          rating: rating,
          comment: comment.trim(),
        );
      } on FirebaseException catch (e) {
        // ReviewPolicy checks attendance locally, so a refusal here is a
        // seat cancelled or an event moved after the screen loaded.
        if (e.code != 'permission-denied') rethrow;
        throw FailureException(
          BusinessRuleFailure(
            rule: BusinessRule.notAttendee,
            message:
                'Seules les personnes inscrites peuvent laisser un avis, une '
                'fois l’événement commencé.',
            cause: e,
          ),
        );
      }
    });
  }

  @override
  AsyncResult<void> delete({required String eventId, required String userId}) =>
      guard(() => _remote.delete(eventId: eventId, authorId: userId));
}
