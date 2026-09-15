import 'package:eventhub/core/errors/failure_exception.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/auth/domain/entities/app_user.dart';
import 'package:eventhub/features/events/domain/entities/event.dart';
import 'package:eventhub/features/reservations/domain/entities/reservation.dart';
import 'package:eventhub/features/waitlist/data/waitlist_remote_data_source.dart';
import 'package:eventhub/features/waitlist/domain/waitlist_policy.dart';
import 'package:eventhub/features/waitlist/domain/waitlist_repository.dart';

class WaitlistRepositoryImpl implements WaitlistRepository {
  const WaitlistRepositoryImpl(this._remote);

  final WaitlistRemoteDataSource _remote;

  @override
  Stream<bool> watchIsWaiting({
    required String eventId,
    required String userId,
  }) => _remote.watchIsWaiting(eventId, userId);

  @override
  Stream<int> watchQueueLength(String eventId) => _remote.watchLength(eventId);

  /// The policy first: the rules would refuse the same cases with a bare
  /// `permission-denied`, not with a sentence.
  @override
  AsyncResult<void> join({
    required Event event,
    required AppUser user,
    required Reservation? reservation,
    required DateTime now,
  }) {
    return guard(() async {
      if (WaitlistPolicy.canJoin(
            event: event,
            user: user,
            reservation: reservation,
            now: now,
          )
          case Err(:final failure)) {
        throw FailureException(failure);
      }
      await _remote.join(event.id, user.id);
    });
  }

  @override
  AsyncResult<void> leave({required String eventId, required String userId}) =>
      guard(() => _remote.leave(eventId, userId));
}
