import 'package:eventhub/core/supabase/db.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// `event_attendance(p_event_id)`: the head count and the short names of
/// the last people who booked, computed on demand by the database.
///
/// Reservations are private to their owner and the event team, so the names
/// are never read from the table: the function returns "Prénom I." only,
/// each keyed by a truncated SHA-256 of the uid — uids never leave the
/// database.
class EventAttendanceRemoteDataSource {
  const EventAttendanceRemoteDataSource(this._client);

  final SupabaseClient _client;

  /// Short names of the latest people who booked, most recent first.
  Future<List<String>> fetchRecentNames(String eventId) async {
    final data = await _client.rpc<Object?>(
      Rpc.eventAttendance,
      params: {'p_event_id': eventId},
    );
    return namesFrom(data is Map<String, dynamic> ? data : null);
  }

  /// Tolerant parser of `{count, recent: [{key, name}]}`: a malformed entry
  /// is skipped, never thrown on.
  static List<String> namesFrom(Map<String, dynamic>? data) {
    final raw = data?['recent'];
    if (raw is! List) return const [];
    return [
      for (final entry in raw)
        if (entry is Map && entry['name'] is String)
          if ((entry['name'] as String).trim().isNotEmpty)
            entry['name'] as String,
    ];
  }
}
