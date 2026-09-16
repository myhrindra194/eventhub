import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/auth/domain/entities/app_user.dart';

/// `organizers/{uid}` — le visage public d'un organisateur (F-10).
///
/// Le nom et la présentation sont tenus en phase avec le profil privé dans le
/// même batch ; chaque compteur ne bouge que dans le batch qui le justifie —
/// un abonnement, un événement publié ou supprimé, un avis — comme l'exigent
/// les règles de sécurité. C'est précisément ce qui rend un nombre d'abonnés
/// ou une note dignes d'être affichés sans serveur pour les arbitrer.
class OrganizerProfile {
  const OrganizerProfile({
    required this.id,
    required this.name,
    this.bio = '',
    this.photoUrl,
    this.followerCount = 0,
    this.eventCount = 0,
    this.ratingSum = 0,
    this.ratingCount = 0,
    this.memberSince,
  });

  final String id;
  final String name;
  final String bio;

  /// Le visage de l'organisateur, recopié depuis son profil privé — seul
  /// endroit où les autres comptes peuvent le voir.
  final String? photoUrl;
  final int followerCount;

  /// Les événements publiés et non supprimés, les passés compris.
  final int eventCount;

  /// Sur les avis visibles de tous ses événements.
  final int ratingSum;
  final int ratingCount;
  final DateTime? memberSince;

  /// `null` tant que personne n'a noté l'un de ses événements. Borné, pour
  /// qu'un compteur surpris en pleine mise à jour n'affiche jamais « 5,3 / 5 ».
  double? get averageRating =>
      ratingCount <= 0 ? null : (ratingSum / ratingCount).clamp(1.0, 5.0);

  bool get hasBio => bio.trim().isNotEmpty;
}

/// Reprend la règle `organizerId != userId` de `following`, pour que le
/// bouton s'explique lui-même au lieu d'attendre un refus sec du serveur.
abstract final class FollowPolicy {
  static Result<void> canFollow({
    required AppUser user,
    required String organizerId,
  }) {
    if (organizerId.isEmpty) {
      return const Err(ValidationFailure(message: 'Organisateur inconnu.'));
    }
    if (organizerId == user.id) {
      return const Err(
        BusinessRuleFailure(
          rule: BusinessRule.cannotFollowSelf,
          message: 'Vous ne pouvez pas vous abonner à votre propre profil.',
        ),
      );
    }
    return const Ok(null);
  }
}
