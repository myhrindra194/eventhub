import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/auth/domain/entities/app_user.dart';
import 'package:eventhub/features/reservations/domain/entities/reservation.dart';

/// Qui peut donner un avis, et ce qu’est un avis valide. Reflète la règle de
/// création `reviews` (`attended()`) : une place confirmée, l’événement
/// commencé, une adresse e-mail vérifiée, une note de 1 à 5, un commentaire
/// de 2 000 caractères au plus.
///
/// Aucune condition de rôle : un seul compte porte les deux espaces, et un
/// organisateur qui a assisté à l’événement d’un autre le note comme
/// n’importe qui. L’équipe de l’événement ne peut pas y détenir de place,
/// elle ne peut donc jamais se noter elle-même.
abstract final class ReviewPolicy {
  static const maxCommentLength = 2000;

  static Result<void> canReview({
    required AppUser user,
    required Reservation? reservation,
    required DateTime now,
  }) {
    if (reservation == null ||
        !reservation.isActive ||
        reservation.userId != user.id) {
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
