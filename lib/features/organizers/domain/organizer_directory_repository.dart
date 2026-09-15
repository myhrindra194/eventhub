import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/organizers/domain/organizer_profile.dart';

/// Public organizer profiles and who the signed-in user follows.
///
/// Following is the document `users/{uid}/following/{organizerId}` — private
/// to the follower, and keyed by the organizer so a duplicate is structurally
/// impossible. The public `followerCount` moves in the same commit, which the
/// security rules require. Both operations are idempotent.
abstract interface class OrganizerDirectoryRepository {
  /// `null` when the account is not (or no longer) an organizer.
  Stream<OrganizerProfile?> watchProfile(String organizerId);

  /// Organizer ids, most recently followed first.
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
