import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/notifications/data/notification_remote_data_source.dart';
import 'package:eventhub/features/notifications/domain/app_notification.dart';
import 'package:eventhub/features/notifications/domain/notification_preferences.dart';
import 'package:eventhub/features/notifications/domain/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  const NotificationRepositoryImpl(this._remote);

  final NotificationRemoteDataSource _remote;

  @override
  Stream<NotificationPreferences> watchPreferences(String userId) =>
      _remote.watchPreferences(userId);

  @override
  AsyncResult<void> savePreferences({
    required String userId,
    required NotificationPreferences preferences,
  }) => guard(() => _remote.savePreferences(userId, preferences));

  @override
  AsyncResult<void> registerDevice({
    required String userId,
    required String token,
    required String platform,
  }) => guard(
    () => _remote.registerDevice(uid: userId, token: token, platform: platform),
  );

  @override
  Stream<List<AppNotification>> watchNotifications(String userId) =>
      _remote.watchNotifications(userId);

  @override
  AsyncResult<void> markRead({
    required String userId,
    required String notificationId,
  }) => guard(() => _remote.markRead(userId, notificationId));

  @override
  AsyncResult<void> markAllRead({required String userId}) =>
      guard(() => _remote.markAllRead(userId));

  @override
  AsyncResult<void> deleteNotification({
    required String userId,
    required String notificationId,
  }) => guard(() => _remote.deleteNotification(userId, notificationId));
}
