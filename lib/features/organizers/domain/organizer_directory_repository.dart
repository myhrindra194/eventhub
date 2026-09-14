import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/organizers/domain/organizer_profile.dart';

/// Public organizer profiles and who the signed-in user follows.
///
/// Following is stored at `users/{uid}/following/{organizerId}` — private to
/// the follower, one document per organizer, so a duplicate is structurally
/// impossible. The public counter is maintained by the `onFollowWritten`
/// Cloud Function, never by the client.
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
