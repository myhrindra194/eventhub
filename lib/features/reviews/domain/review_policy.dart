import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/auth/domain/entities/app_user.dart';
import 'package:eventhub/features/reservations/domain/entities/reservation.dart';

/// Who may review, and what a valid review is. Mirrors the `reviews` insert
/// policy (`private.can_review`) and the table constraints: participant,
/// confirmed seat, event started, verified email, rating 1..5, comment ≤
/// 2 000 characters.
abstract final class ReviewPolicy {
  static const maxCommentLength = 2000;

  static Result<void> canReview({
    required AppUser user,
    required Reservation? reservation,
    required DateTime now,
  }) {
    if (!user.isParticipant || reservation == null || !reservation.isActive) {
      return const Err(
        BusinessRuleFailure(
          rule: BusinessRule.notAttendee,
          message: 'Seules les personnes inscrites peuvent laisser un avis.',
        ),
      );
    }
    if (reservation.eventStartsAt.isAfter(now)) {
      return const Err(
        BusinessRuleFailure(
          rule: BusinessRule.eventNotStarted,
          message: 'Les avis ouvrent au début de l’événement.',
        ),
      );
    }
    if (!user.emailVerified) {
      return const Err(
        BusinessRuleFailure(
          rule: BusinessRule.emailNotVerified,
          message: 'Confirmez votre adresse email pour publier un avis.',
        ),
      );
    }
    return const Ok(null);
  }

  static Result<void> validate({required int rating, required String comment}) {
    final errors = <String, String>{
      if (rating < 1 || rating > 5) 'rating': 'Choisissez une note de 1 à 5.',
      if (comment.trim().length > maxCommentLength)
        'comment': '$maxCommentLength caractères maximum.',
    };
    if (errors.isEmpty) return const Ok(null);
    return Err(
      ValidationFailure(message: errors.values.first, fieldErrors: errors),
    );
  }
}
