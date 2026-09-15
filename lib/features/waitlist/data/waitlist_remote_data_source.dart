import 'package:eventhub/core/supabase/db.dart';
import 'package:eventhub/core/supabase/supabase_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// `public.waitlist_entries` — one row per `(event_id, user_id)`, FIFO by
/// `created_at`. Read by the person queued and by the event team; written
/// only by `join_waitlist` / `leave_waitlist`, which take the name from the
/// profile and the position from the server clock.
class WaitlistRemoteDataSource {
  const WaitlistRemoteDataSource(this._client);

  final SupabaseClient _client;

  static const _primaryKey = ['event_id', 'user_id'];

  /// Filtered on the user, not the event: the channel then carries the
  /// person's own entries only, whatever the size of the queue.
  Stream<bool> watchIsWaiting(String eventId, String userId) => _client
      .from(Tables.waitlistEntries)
      .stream(primaryKey: _primaryKey)
      .eq('user_id', userId)
      .map((rows) => rows.any((row) => row['event_id'] == eventId))
      .distinct()
      .resilient('waitlist:mine:$eventId');

  Stream<int> watchLength(String eventId) => _client
      .from(Tables.waitlistEntries)
      .stream(primaryKey: _primaryKey)
      .eq('event_id', eventId)
      .map((rows) => rows.length)
      .distinct()
      .resilient('waitlist:$eventId');

  Future<void> join(String eventId) async {
    await _client.rpc<void>(Rpc.joinWaitlist, params: {'p_event_id': eventId});
  }

  Future<void> leave(String eventId) async {
    await _client.rpc<void>(Rpc.leaveWaitlist, params: {'p_event_id': eventId});
  }
}
