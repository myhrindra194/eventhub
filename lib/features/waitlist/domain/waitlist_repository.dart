import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/auth/domain/entities/app_user.dart';
import 'package:eventhub/features/events/domain/entities/event.dart';
import 'package:eventhub/features/reservations/domain/entities/reservation.dart';

abstract interface class WaitlistRepository {
  /// The rules let a client list at most this many entries of a queue.
  static const queueLengthCap = 20;

  /// Whether [userId] is queued for [eventId].
  Stream<bool> watchIsWaiting({
    required String eventId,
    required String userId,
  });

  /// Number of people queued, for the event team, capped at
  /// [queueLengthCap]: a value equal to the cap reads "20 ou plus".
  Stream<int> watchQueueLength(String eventId);

  /// Checks `WaitlistPolicy.canJoin` before writing; the rules check the
  /// same conditions again.
  AsyncResult<void> join({
    required Event event,
    required AppUser user,
    required Reservation? reservation,
    required DateTime now,
  });

  /// Leaves [userId]'s own entry; a no-op when there is none.
  AsyncResult<void> leave({required String eventId, required String userId});
}
