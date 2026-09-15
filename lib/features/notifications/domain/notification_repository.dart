import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/notifications/domain/app_notification.dart';
import 'package:eventhub/features/notifications/domain/notification_preferences.dart';

/// Persistence of what the push pipeline needs on the server side — where to
/// send (devices) and whether to send (preferences) — and of the in-app
/// history the server writes. Sending itself is not here: the database
/// enqueues a push job per notification and the `worker` Edge Function
/// delivers it through FCM.
abstract interface class NotificationRepository {
  Stream<NotificationPreferences> watchPreferences(String userId);

  AsyncResult<void> savePreferences({
    required String userId,
    required NotificationPreferences preferences,
  });

  /// Upserts this installation's device row with the FCM [token].
  /// Idempotent: called on every sign-in and on every token refresh.
  AsyncResult<void> registerDevice({
    required String userId,
    required String token,
    required String platform,
  });

  /// Most recent first, bounded.
  Stream<List<AppNotification>> watchNotifications(String userId);

  AsyncResult<void> markRead({
    required String userId,
    required String notificationId,
  });

  /// Marks every unread notification of [userId] as read, in one statement
  /// on the server — including entries older than the bounded feed.
  AsyncResult<void> markAllRead({required String userId});

  AsyncResult<void> deleteNotification({
    required String userId,
    required String notificationId,
  });
}
