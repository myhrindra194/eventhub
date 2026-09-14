import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Displays pushes received while the app is in the foreground — FCM does
/// not show those — and owns the Android notification channel.
class LocalNotificationDataSource {
  LocalNotificationDataSource([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  /// Must match `default_notification_channel_id` in AndroidManifest.xml and
  /// `ANDROID_CHANNEL` in the Cloud Functions.
  static const channelId = 'eventhub_default';

  static const _channel = AndroidNotificationChannel(
    channelId,
    'Réservations et rappels',
    description: 'Nouvelles réservations, annulations et rappels J-1.',
    importance: Importance.high,
  );

  /// [onTap] receives the message data (the same map FCM delivers).
  Future<void> initialize({
    required void Function(Map<String, Object?> data) onTap,
  }) async {
    if (_initialized) return;
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // FCM already asks for permission; asking twice would show two
        // prompts on iOS.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        final decoded = jsonDecode(payload);
        if (decoded is Map<String, Object?>) onTap(decoded);
      },
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);
    _initialized = true;
  }

  Future<void> show(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    await _plugin.show(
      id: (message.messageId ?? '${DateTime.now().microsecondsSinceEpoch}')
          .hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
  }
}
