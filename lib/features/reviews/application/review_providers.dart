import 'package:eventhub/core/analytics/app_analytics.dart';
import 'package:eventhub/core/config/app_config.dart';
import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/firebase/firebase_providers.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/auth/application/auth_providers.dart';
import 'package:eventhub/features/auth/domain/entities/app_user.dart';
import 'package:eventhub/features/reservations/application/reservation_providers.dart';
import 'package:eventhub/features/reviews/data/review_remote_data_source.dart';
import 'package:eventhub/features/reviews/data/review_repository_impl.dart';
import 'package:eventhub/features/reviews/domain/review.dart';
import 'package:eventhub/features/reviews/domain/review_policy.dart';
import 'package:eventhub/features/reviews/domain/review_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' hide AsyncResult;

part 'review_providers.g.dart';

@Riverpod(keepAlive: true)
ReviewRepository reviewRepository(Ref ref) =>
    ReviewRepositoryImpl(ReviewRemoteDataSource(ref.watch(firestoreProvider)));

@riverpod
Stream<List<Review>> eventReviews(Ref ref, String eventId) =>
    ref.watch(reviewRepositoryProvider).watchEventReviews(eventId);

@riverpod
Stream<Review?> myReview(Ref ref, String eventId) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);
  return ref
      .watch(reviewRepositoryProvider)
      .watchReview(eventId: eventId, userId: user.id);
}

/// Whether the signed-in user may review [eventId] now.
@riverpod
bool canReviewEvent(Ref ref, String eventId) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  final result = ReviewPolicy.canReview(
    user: user,
    reservation: ref.watch(myReservationForEventProvider(eventId)).value,
    now: ref.watch(clockProvider)(),
  );
  return result is Ok<void>;
}

@riverpod
class ReviewController extends _$ReviewController {
  @override
  FutureOr<void> build() {}

  Future<Result<void>> save({
    required String eventId,
    required int rating,
    required String comment,
  }) async {
    final result = await _run(
      (user) => ref
          .read(reviewRepositoryProvider)
          .save(
            user: user,
            reservation: ref.read(myReservationForEventProvider(eventId)).value,
            eventId: eventId,
            rating: rating,
            comment: comment,
            exists: ref.read(myReviewProvider(eventId)).value != null,
            now: ref.read(clockProvider)(),
          ),
    );
    if (result is Ok<void>) {
      ref.read(appAnalyticsProvider).reviewPublished(eventId, rating);
    }
    return result;
  }

  Future<Result<void>> delete(String eventId) => _run(
    (user) => ref
        .read(reviewRepositoryProvider)
        .delete(eventId: eventId, userId: user.id),
  );

  Future<Result<void>> _run(
    AsyncResult<void> Function(AppUser user) action,
  ) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return const Err(AuthFailure.notSignedIn());
    state = const AsyncLoading();
    final result = await action(user);
    state = switch (result) {
      Ok() => const AsyncData(null),
      Err(:final failure) => AsyncError(
        failure,
        failure.stackTrace ?? StackTrace.current,
      ),
    };
    return result;
  }
}
