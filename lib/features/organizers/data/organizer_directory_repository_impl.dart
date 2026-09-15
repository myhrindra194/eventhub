import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/errors/failure_exception.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/organizers/data/organizer_directory_remote_data_source.dart';
import 'package:eventhub/features/organizers/domain/organizer_directory_repository.dart';
import 'package:eventhub/features/organizers/domain/organizer_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

class OrganizerDirectoryRepositoryImpl implements OrganizerDirectoryRepository {
  const OrganizerDirectoryRepositoryImpl(this._remote);

  final OrganizerDirectoryRemoteDataSource _remote;

  @override
  Stream<OrganizerProfile?> watchProfile(String organizerId) =>
      _remote.watchProfile(organizerId);

  @override
  Stream<List<String>> watchFollowingIds(String userId) =>
      _remote.watchFollowingIds(userId);

  @override
  AsyncResult<void> follow({
    required String userId,
    required String organizerId,
  }) => guard(() async {
    try {
      await _remote.follow(organizerId);
    } on PostgrestException catch (e) {
      switch (e.code) {
        // Already following (a double tap, a stale button): the wanted state
        // holds, which is all the user asked for.
        case '23505':
          return;
        // `follows_not_self`: FollowPolicy stops it first; this keeps the
        // same sentence if the check is ever bypassed.
        case '23514':
          throw FailureException(
            BusinessRuleFailure(
              rule: BusinessRule.cannotFollowSelf,
              message: 'Vous ne pouvez pas vous abonner à votre propre profil.',
              cause: e,
            ),
          );
      }
      rethrow;
    }
  });

  @override
  AsyncResult<void> unfollow({
    required String userId,
    required String organizerId,
  }) => guard(() => _remote.unfollow(userId, organizerId));
}
