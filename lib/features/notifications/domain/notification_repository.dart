import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/notifications/domain/app_notification.dart';
import 'package:eventhub/features/notifications/domain/notification_preferences.dart';

/// Persistence of what the push pipeline needs on the server side — where to
/// send (devices) and whether to send (preferences) — and of the in-app
/// history the server writes. Sending itself is not here: it is a Cloud
/// Functions concern (`functions/src/index.ts`).
abstract interface class NotificationRepository {
  Stream<NotificationPreferences> watchPreferences(String userId);

  AsyncResult<void> savePreferences({
    required String userId,
    required NotificationPreferences preferences,
  });

  /// Upserts the device document for this FCM [token]. Idempotent: called
  /// on every sign-in and on every token refresh.
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

  /// One batched write, however many ids.
  AsyncResult<void> markAllRead({
    required String userId,
    required List<String> notificationIds,
  });

  AsyncResult<void> deleteNotification({
    required String userId,
    required String notificationId,
  });
}
