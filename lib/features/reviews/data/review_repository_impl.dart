import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/errors/failure_exception.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/auth/domain/entities/app_user.dart';
import 'package:eventhub/features/reservations/domain/entities/reservation.dart';
import 'package:eventhub/features/reviews/data/review_remote_data_source.dart';
import 'package:eventhub/features/reviews/domain/review.dart';
import 'package:eventhub/features/reviews/domain/review_policy.dart';
import 'package:eventhub/features/reviews/domain/review_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

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
  }) => _remote.watchAuthorReview(eventId: eventId, authorId: userId);

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
      final text = comment.trim();
      Future<void> update() => _remote.update(
        eventId: eventId,
        authorId: user.id,
        rating: rating,
        comment: text,
      );

      if (exists) return update();
      try {
        await _remote.create(eventId: eventId, rating: rating, comment: text);
      } on PostgrestException catch (e) {
        switch (e.code) {
          // `reviews_one_per_author`: the review was created meanwhile (a
          // second device, a stream not caught up yet) — editing it is what
          // the person meant.
          case '23505':
            return update();
          // The insert policy refused: `private.can_review` found no
          // confirmed seat on a started event with a verified email.
          // ReviewPolicy checks the same locally, so this is a reservation
          // cancelled or an event moved after the screen loaded.
          case '42501':
            throw FailureException(
              BusinessRuleFailure(
                rule: BusinessRule.notAttendee,
                message:
                    'Seules les personnes inscrites peuvent laisser un avis, '
                    'une fois l’événement commencé.',
                cause: e,
              ),
            );
        }
        rethrow;
      }
    });
  }

  @override
  AsyncResult<void> delete({required String eventId, required String userId}) =>
      guard(() => _remote.delete(eventId: eventId, authorId: userId));
}
