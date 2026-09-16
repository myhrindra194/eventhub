import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/auth/domain/entities/app_user.dart';
import 'package:eventhub/features/reservations/domain/entities/reservation.dart';
import 'package:eventhub/features/reviews/domain/review.dart';

abstract interface class ReviewRepository {
  /// Les plus récents d’abord, bornés aux 100 derniers, les avis masqués
  /// écartés.
  Stream<List<Review>> watchEventReviews(String eventId);

  /// L’avis de [userId] sur [eventId], masqué ou non (son auteur continue de
  /// le voir).
  Stream<Review?> watchReview({
    required String eventId,
    required String userId,
  });

  /// Un avis par son id, pour la modération : les administrateurs voient
  /// aussi les avis masqués.
  Stream<Review?> watchReviewById(String reviewId);

  /// Crée ou modifie l’avis de l’utilisateur après contrôle de
  /// `ReviewPolicy` ; la note de l’organisateur bouge dans la même
  /// transaction.
  AsyncResult<void> save({
    required AppUser user,
    required Reservation? reservation,
    required String eventId,
    required int rating,
    required String comment,
    required DateTime now,
  });

  AsyncResult<void> delete({required String eventId, required String userId});
}
