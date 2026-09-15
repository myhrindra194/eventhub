import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/errors/failure_exception.dart';
import 'package:eventhub/core/supabase/db.dart';
import 'package:eventhub/core/supabase/supabase_providers.dart';
import 'package:eventhub/core/utils/app_logger.dart';
import 'package:eventhub/core/utils/date_formats.dart';
import 'package:eventhub/features/notifications/data/device_id_store.dart';
import 'package:eventhub/features/notifications/data/notification_dto.dart';
import 'package:eventhub/features/notifications/domain/app_notification.dart';
import 'package:eventhub/features/notifications/domain/notification_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// `public.notifications`, `public.notification_preferences` and
/// `public.devices` for the signed-in user.
///
/// Every query also filters on `user_id` although RLS already confines the
/// rows to their owner: the filter lets Postgres use
/// `notifications_user_idx`, and turns a wrong uid into an empty result rather
/// than a silent reliance on the policy.
class NotificationRemoteDataSource {
  NotificationRemoteDataSource(this._client, {DeviceIdStore? deviceIds})
    : _deviceIds = deviceIds ?? DeviceIdStore();

  final SupabaseClient _client;
  final DeviceIdStore _deviceIds;

  // ------------------------------------------------------------ preferences

  /// The row is created with the profile; until Realtime delivers it (or if
  /// it is somehow missing) the defaults apply, which match the column
  /// defaults.
  Stream<NotificationPreferences> watchPreferences(String uid) => _client
      .from(Tables.notificationPreferences)
      .stream(primaryKey: ['user_id'])
      .eq('user_id', uid)
      .map(
        (rows) => rows.isEmpty
            ? const NotificationPreferences()
            : NotificationPreferencesDto.fromJson(rows.first).toDomain(),
      )
      .resilient('notification-preferences');

  /// Updates the three granted columns. An update matching no row succeeds
  /// silently in PostgREST, so the returned rows are checked: a missing row
  /// would otherwise look like a saved preference that the server ignores.
  Future<void> savePreferences(
    String uid,
    NotificationPreferences prefs,
  ) async {
    final rows = await _client
        .from(Tables.notificationPreferences)
        .update(NotificationPreferencesDto.fromDomain(prefs).toJson())
        .eq('user_id', uid)
        .select('user_id');
    if (rows.isEmpty) {
      throw const FailureException(
        NotFoundFailure(
          resource: Tables.notificationPreferences,
          message: 'Préférences introuvables. Reconnectez-vous puis réessayez.',
        ),
      );
    }
  }

  // ---------------------------------------------------------- notifications

  /// Bounded: the purge keeps 30 days, a very active organizer can still
  /// accumulate hundreds; the screen shows the most recent ones.
  static const maxNotifications = 100;

  /// Realtime accepts a single filter, so expiry and the bound are applied in
  /// [notificationsFromRows].
  Stream<List<AppNotification>> watchNotifications(String uid) => _client
      .from(Tables.notifications)
      .stream(primaryKey: ['id'])
      .eq('user_id', uid)
      .order('created_at')
      .map(notificationsFromRows)
      .resilient('notifications');

  /// `read_at` is the only column granted for update; the trigger
  /// `notifications_before_update` replaces the value with the server time
  /// and never un-reads, so the client clock is irrelevant.
  Future<void> markRead(String uid, String notificationId) async {
    await _client
        .from(Tables.notifications)
        .update({'read_at': _now()})
        .eq('id', notificationId)
        .eq('user_id', uid);
  }

  /// One statement for every unread row, including those beyond
  /// [maxNotifications] that the feed does not show: "tout marquer comme lu"
  /// means all of them.
  Future<void> markAllRead(String uid) async {
    await _client
        .from(Tables.notifications)
        .update({'read_at': _now()})
        .eq('user_id', uid)
        .isFilter('read_at', null);
  }

  Future<void> deleteNotification(String uid, String notificationId) async {
    await _client
        .from(Tables.notifications)
        .delete()
        .eq('id', notificationId)
        .eq('user_id', uid);
  }

  static String _now() => DateTime.now().toUtc().toIso8601String();

  /// Most recent first, unexpired, bounded.
  ///
  /// Tolerant: a row that cannot be parsed is skipped and logged rather than
  /// failing the whole list, since one emission carries every row.
  static List<AppNotification> notificationsFromRows(
    List<Map<String, dynamic>> rows, {
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    final parsed = <NotificationDto>[];
    for (final row in rows) {
      try {
        parsed.add(NotificationDto.fromJson(row));
      } on Object catch (error) {
        AppLogger.warning('Malformed notification ${row['id']}', error: error);
      }
    }
    final visible =
        parsed
            .where(
              (n) => n.expiresAt == null || n.expiresAt!.isAfter(reference),
            )
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return [for (final dto in visible.take(maxNotifications)) dto.toDomain()];
  }

  // ---------------------------------------------------------------- devices

  /// Registers this installation's FCM [token] for the signed-in user.
  ///
  /// Goes through `public.register_device` (the table is not client
  /// writable): it takes the user from the JWT — [uid] is not sent — and
  /// removes the same token from any other account, so a phone shared
  /// between two accounts only ever notifies the one signed in.
  Future<void> registerDevice({
    required String uid,
    required String token,
    required String platform,
  }) async {
    await _client.rpc<void>(
      Rpc.registerDevice,
      params: {
        'p_device_id': await _deviceIds.read(token: token),
        'p_token': token,
        'p_platform': platform,
        'p_locale': AppDateFormats.locale,
      },
    );
  }
}
