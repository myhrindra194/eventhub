import 'package:eventhub/core/supabase/db.dart';
import 'package:eventhub/core/supabase/supabase_providers.dart';
import 'package:eventhub/features/auth/data/dtos/user_dto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// `public.profiles`, the signed-in user's own row (RLS: owner only).
class UserRemoteDataSource {
  const UserRemoteDataSource(this._client);

  final SupabaseClient _client;

  /// The email is overwritten from Auth and `created_at` stamped by the
  /// database; the role is chosen once, here.
  Future<void> create(String uid, UserDto dto) async {
    await _client.from(Tables.profiles).insert({
      'id': uid,
      'name': dto.name,
      'email': dto.email,
      'role': dto.role.name,
      if (dto.bio != null) 'bio': dto.bio,
    });
  }

  /// Only the columns a client may update (`name`, `bio`). An empty bio is
  /// stored as null.
  Future<void> updateProfile(
    String uid, {
    required String name,
    String? bio,
  }) async {
    await _client
        .from(Tables.profiles)
        .update({
          'name': name,
          if (bio != null) 'bio': bio.isEmpty ? null : bio,
        })
        .eq('id', uid);
  }

  Future<UserDto?> get(String uid) async {
    final row = await _client
        .from(Tables.profiles)
        .select()
        .eq('id', uid)
        .maybeSingle();
    return row == null ? null : UserDto.fromJson(row);
  }

  Stream<UserDto?> watch(String uid) => _client
      .from(Tables.profiles)
      .stream(primaryKey: ['id'])
      .eq('id', uid)
      .map((rows) => rows.isEmpty ? null : UserDto.fromJson(rows.first))
      .resilient('profile');
}
