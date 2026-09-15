import 'package:eventhub/core/supabase/db.dart';
import 'package:eventhub/core/supabase/supabase_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// `public.favorites` (RLS: owner only). `user_id` defaults to `auth.uid()`
/// and is not even insertable, so a favourite can only ever be one's own.
class FavoritesRemoteDataSource {
  const FavoritesRemoteDataSource(this._client);

  final SupabaseClient _client;

  /// Generous but bounded: a Realtime subscription replays its whole result
  /// on each change.
  static const maxFavorites = 500;

  /// SQLSTATE `unique_violation`.
  static const _alreadyStarred = '23505';

  Stream<List<String>> watchIds(String uid) => _client
      .from(Tables.favorites)
      .stream(primaryKey: ['user_id', 'event_id'])
      .eq('user_id', uid)
      .order('created_at')
      .limit(maxFavorites)
      .map((rows) => [for (final row in rows) row['event_id'] as String])
      .resilient('favorites');

  /// Idempotent, like the toggle expects: starring twice (two taps racing,
  /// another device) is not an error. The primary key `(user_id, event_id)`
  /// makes the duplicate impossible; its violation is swallowed here.
  Future<void> add(String eventId) async {
    try {
      await _client.from(Tables.favorites).insert({'event_id': eventId});
    } on PostgrestException catch (e) {
      if (e.code != _alreadyStarred) rethrow;
    }
  }

  Future<void> remove(String uid, String eventId) async {
    await _client
        .from(Tables.favorites)
        .delete()
        .eq('user_id', uid)
        .eq('event_id', eventId);
  }
}
