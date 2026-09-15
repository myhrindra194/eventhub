import 'package:eventhub/core/supabase/db.dart';
import 'package:eventhub/core/supabase/supabase_providers.dart';
import 'package:eventhub/features/organizers/data/organizer_profile_dto.dart';
import 'package:eventhub/features/organizers/domain/organizer_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// `public.organizers` (read-only) and `public.follows` (RLS: a follower
/// sees, inserts and deletes only their own rows).
class OrganizerDirectoryRemoteDataSource {
  const OrganizerDirectoryRemoteDataSource(this._client);

  final SupabaseClient _client;

  /// Bounded like favourites: the initial fetch of a Realtime stream loads
  /// every matching row.
  static const maxFollowing = 500;

  Stream<OrganizerProfile?> watchProfile(String organizerId) => _client
      .from(Tables.organizers)
      .stream(primaryKey: ['id'])
      .eq('id', organizerId)
      .map((rows) => rows.isEmpty ? null : profileFromRow(rows.first))
      .resilient('organizer-profile');

  Stream<List<String>> watchFollowingIds(String uid) => _client
      .from(Tables.follows)
      .stream(primaryKey: ['follower_id', 'organizer_id'])
      .eq('follower_id', uid)
      .order('created_at')
      .limit(maxFollowing)
      .map(
        (rows) => [
          for (final row in rows)
            if (row['organizer_id'] case final String id) id,
        ],
      )
      .resilient('following');

  /// Only `organizer_id` is client-writable: `follower_id` defaults to
  /// `auth.uid()` and RLS refuses any other value.
  Future<void> follow(String organizerId) =>
      _client.from(Tables.follows).insert({'organizer_id': organizerId});

  Future<void> unfollow(String uid, String organizerId) => _client
      .from(Tables.follows)
      .delete()
      .eq('follower_id', uid)
      .eq('organizer_id', organizerId);

  static OrganizerProfile profileFromRow(Map<String, dynamic> row) =>
      OrganizerProfileDto.fromJson(row).toDomain();
}
