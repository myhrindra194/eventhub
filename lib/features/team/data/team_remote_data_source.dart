import 'package:eventhub/core/supabase/db.dart';
import 'package:eventhub/core/supabase/supabase_providers.dart';
import 'package:eventhub/features/team/data/staff_invitation_dto.dart';
import 'package:eventhub/features/team/domain/team.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// `public.staff_invitations` (RLS: the invitee and the event team) and the
/// three team RPCs, which own every write and every invariant (owner only,
/// organizers only, ten seats).
class TeamRemoteDataSource {
  const TeamRemoteDataSource(this._client);

  final SupabaseClient _client;

  /// A team has at most ten members; the bound covers a long history of
  /// answered invitations too.
  static const maxInvitations = 50;

  Stream<List<StaffInvitation>> watchPendingForEvent(String eventId) =>
      _pending('event_id', eventId, label: 'event-invitations');

  Stream<List<StaffInvitation>> watchPendingForUser(String userId) =>
      _pending('user_id', userId, label: 'my-invitations');

  /// Realtime takes one filter: the status is matched here, so an answered
  /// invitation leaves the list as soon as its row changes.
  Stream<List<StaffInvitation>> _pending(
    String column,
    String value, {
    required String label,
  }) => _client
      .from(Tables.staffInvitations)
      .stream(primaryKey: ['event_id', 'user_id'])
      .eq(column, value)
      .order('created_at')
      .limit(maxInvitations)
      .map(
        (rows) => [
          for (final row in rows)
            if (row['status'] == 'pending') invitationFromRow(row),
        ],
      )
      .resilient(label);

  /// The function answers `{user_id, name}`; the pending list shows the
  /// invitation through Realtime, so the answer is not needed here.
  Future<void> invite({required String eventId, required String email}) =>
      _client.rpc<void>(
        Rpc.inviteCoOrganizer,
        params: {'p_event_id': eventId, 'p_email': email},
      );

  Future<void> respond({required String eventId, required bool accept}) =>
      _client.rpc<void>(
        Rpc.respondToStaffInvite,
        params: {'p_event_id': eventId, 'p_accept': accept},
      );

  Future<void> remove({required String eventId, required String userId}) =>
      _client.rpc<void>(
        Rpc.removeCoOrganizer,
        params: {'p_event_id': eventId, 'p_user_id': userId},
      );

  static StaffInvitation invitationFromRow(Map<String, dynamic> row) =>
      StaffInvitationDto.fromJson(row).toDomain();
}
