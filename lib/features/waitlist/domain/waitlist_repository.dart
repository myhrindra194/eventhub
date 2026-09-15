import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/auth/domain/entities/app_user.dart';
import 'package:eventhub/features/events/domain/entities/event.dart';
import 'package:eventhub/features/reservations/domain/entities/reservation.dart';

abstract interface class WaitlistRepository {
  /// Whether [userId] is queued for [eventId].
  Stream<bool> watchIsWaiting({
    required String eventId,
    required String userId,
  });

  /// Number of people queued — readable by the event team only.
  Stream<int> watchQueueLength(String eventId);

  /// Checks `WaitlistPolicy.canJoin` before asking the server, which checks
  /// the same rules again.
  AsyncResult<void> join({
    required Event event,
    required AppUser user,
    required Reservation? reservation,
    required DateTime now,
  });

  /// Leaves the signed-in user's own entry; a no-op when there is none.
  AsyncResult<void> leave({required String eventId});
}
