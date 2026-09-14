import 'package:eventhub/core/result/result.dart';

/// `events/{eventId}/checkins/{reservationId}` — append-only scan records,
/// readable and writable by the event's organizer only.
abstract interface class CheckInRepository {
  /// reservationId → first scan time.
  Stream<Map<String, DateTime>> watchCheckIns(String eventId);

  AsyncResult<DateTime?> checkedInAt({
    required String eventId,
    required String reservationId,
  });

  /// `true` when this call recorded the entry, `false` when another scanner
  /// recorded it first (the rules refuse overwriting a check-in).
  AsyncResult<bool> record({
    required String eventId,
    required String reservationId,
    required String organizerId,
  });
}
