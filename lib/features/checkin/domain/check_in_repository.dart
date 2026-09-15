import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/checkin/domain/check_in_policy.dart';

/// `events/{eventId}/checkins/{reservationId}` — one entry per admitted
/// ticket, readable and writable by the event team only, never updated nor
/// deleted.
abstract interface class CheckInRepository {
  /// reservationId → first scan time.
  Stream<Map<String, DateTime>> watchCheckIns(String eventId);

  /// Judges the ticket and, when it is valid and unused, records the entry
  /// scanned by [scannedBy], in one transaction.
  AsyncResult<CheckInVerdict> checkIn({
    required String eventId,
    required String reservationId,
    required String scannedBy,
  });
}
