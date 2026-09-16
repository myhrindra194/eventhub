import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/organizers/domain/organizer_profile.dart';

/// Les pages publiques des organisateurs, et la liste de ceux que le compte
/// connecté suit.
///
/// Un abonnement est le document `users/{uid}/following/{organizerId}` :
/// privé à l'abonné, et identifié par l'organisateur, ce qui rend un doublon
/// structurellement impossible. Le compteur public `followerCount` bouge dans
/// le même commit, comme l'exigent les règles de sécurité. Les deux
/// opérations sont idempotentes.
abstract interface class OrganizerDirectoryRepository {
  /// `null` quand le compte n'est pas — ou n'est plus — organisateur.
  Stream<OrganizerProfile?> watchProfile(String organizerId);

  /// Les identifiants des organisateurs, du plus récemment suivi au plus
  /// ancien.
  Stream<List<String>> watchFollowingIds(String userId);

  AsyncResult<void> follow({
    required String userId,
    required String organizerId,
  });

  AsyncResult<void> unfollow({
    required String userId,
    required String organizerId,
  });
}
