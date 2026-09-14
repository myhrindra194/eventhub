import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/team/data/team_remote_data_source.dart';
import 'package:eventhub/features/team/domain/team.dart';
import 'package:eventhub/features/team/domain/team_repository.dart';

class TeamRepositoryImpl implements TeamRepository {
  const TeamRepositoryImpl(this._remote);

  final TeamRemoteDataSource _remote;

  @override
  Stream<List<StaffInvitation>> watchPendingForEvent(String eventId) =>
      _remote.watchPendingForEvent(eventId);

  @override
  Stream<List<StaffInvitation>> watchPendingForUser(String userId) =>
      _remote.watchPendingForUser(userId);

  @override
  AsyncResult<void> invite({required String eventId, required String email}) =>
      guard(
        () =>
            _remote.invite(eventId: eventId, email: email.trim().toLowerCase()),
      );

  @override
  AsyncResult<void> respond({required String eventId, required bool accept}) =>
      guard(() => _remote.respond(eventId: eventId, accept: accept));

  @override
  AsyncResult<void> remove({required String eventId, required String userId}) =>
      guard(() => _remote.remove(eventId: eventId, userId: userId));
}
