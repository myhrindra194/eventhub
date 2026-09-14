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

  /// Number of people queued — readable by the event's organizer only.
  Stream<int> watchQueueLength(String eventId);

  /// Checks `WaitlistPolicy.canJoin` before writing.
  AsyncResult<void> join({
    required Event event,
    required AppUser user,
    required Reservation? reservation,
    required DateTime now,
  });

  AsyncResult<void> leave({required String eventId, required String userId});
}
