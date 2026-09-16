import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/errors/failure_exception.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/organizers/data/organizer_directory_remote_data_source.dart';
import 'package:eventhub/features/organizers/domain/organizer_directory_repository.dart';
import 'package:eventhub/features/organizers/domain/organizer_profile.dart';

class OrganizerDirectoryRepositoryImpl implements OrganizerDirectoryRepository {
  const OrganizerDirectoryRepositoryImpl(this._remote);

  final OrganizerDirectoryRemoteDataSource _remote;

  @override
  Stream<OrganizerProfile?> watchProfile(String organizerId) =>
      _remote.watchProfile(organizerId);

  @override
  Stream<List<String>> watchFollowingIds(String userId) =>
      _remote.watchFollowingIds(userId);

  /// Les règles refusent l'abonnement à soi-même par un simple
  /// `permission-denied`, qui n'explique rien. La même règle est donc
  /// revérifiée ici en premier, pour que la phrase affichée reste juste même
  /// si un appelant a contourné [FollowPolicy].
  @override
  AsyncResult<void> follow({
    required String userId,
    required String organizerId,
  }) => guard(() async {
    if (organizerId.isEmpty) {
      throw const FailureException(
        ValidationFailure(message: 'Organisateur inconnu.'),
      );
    }
    if (organizerId == userId) throw const FailureException(_followSelf);
    await _remote.follow(userId, organizerId);
  });

  @override
  AsyncResult<void> unfollow({
    required String userId,
    required String organizerId,
  }) => guard(() => _remote.unfollow(userId, organizerId));

  static const _followSelf = BusinessRuleFailure(
    rule: BusinessRule.cannotFollowSelf,
    message: 'Vous ne pouvez pas vous abonner à votre propre profil.',
  );
}
