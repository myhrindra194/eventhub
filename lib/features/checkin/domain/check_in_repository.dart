import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/checkin/domain/check_in_policy.dart';

/// `public.checkins` — one row per admitted ticket, readable by the event
/// team, written only by the `check_in_ticket` function.
abstract interface class CheckInRepository {
  /// reservationId → first scan time.
  Stream<Map<String, DateTime>> watchCheckIns(String eventId);

  /// Judges the ticket and, when it is valid and unused, records the entry,
  /// in one transaction.
  AsyncResult<CheckInVerdict> checkIn({
    required String eventId,
    required String reservationId,
  });
}
