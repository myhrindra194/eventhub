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

  @override
  AsyncResult<void> follow({
    required String userId,
    required String organizerId,
  }) => guard(() => _remote.follow(userId, organizerId));

  @override
  AsyncResult<void> unfollow({
    required String userId,
    required String organizerId,
  }) => guard(() => _remote.unfollow(userId, organizerId));
}
