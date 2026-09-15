import 'dart:async';

import 'package:eventhub/core/config/app_config.dart';
import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/firebase/firebase_providers.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/core/supabase/supabase_providers.dart';
import 'package:eventhub/core/utils/app_logger.dart';
import 'package:eventhub/features/auth/application/auth_providers.dart';
import 'package:eventhub/features/auth/domain/entities/app_user.dart';
import 'package:eventhub/features/notifications/application/notification_route.dart';
import 'package:eventhub/features/notifications/data/local_notification_data_source.dart';
import 'package:eventhub/features/notifications/data/notification_remote_data_source.dart';
import 'package:eventhub/features/notifications/data/notification_repository_impl.dart';
import 'package:eventhub/features/notifications/data/push_messaging_data_source.dart';
import 'package:eventhub/features/notifications/domain/app_notification.dart';
import 'package:eventhub/features/notifications/domain/notification_preferences.dart';
import 'package:eventhub/features/notifications/domain/notification_repository.dart';
import 'package:eventhub/routes/routes.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' hide AsyncResult;

part 'notification_providers.g.dart';

@Riverpod(keepAlive: true)
NotificationRepository notificationRepository(Ref ref) =>
    NotificationRepositoryImpl(
      NotificationRemoteDataSource(ref.watch(supabaseClientProvider)),
    );

@Riverpod(keepAlive: true)
PushMessagingDataSource pushMessaging(Ref ref) =>
    PushMessagingDataSource(ref.watch(firebaseMessagingProvider));

@Riverpod(keepAlive: true)
LocalNotificationDataSource localNotifications(Ref ref) =>
    LocalNotificationDataSource();

/// Preferences of the signed-in user; defaults while signed out.
@riverpod
Stream<NotificationPreferences> notificationPreferences(Ref ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(const NotificationPreferences());
  return ref.watch(notificationRepositoryProvider).watchPreferences(user.id);
}

@riverpod
class NotificationPreferencesController
    extends _$NotificationPreferencesController {
  @override
  FutureOr<void> build() {}

  Future<Result<void>> save(NotificationPreferences preferences) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return const Err(AuthFailure.notSignedIn());
    state = const AsyncLoading();
    final result = await ref
        .read(notificationRepositoryProvider)
        .savePreferences(userId: user.id, preferences: preferences);
    state = switch (result) {
      Ok() => const AsyncData(null),
      Err(:final failure) => AsyncError(
        failure,
        failure.stackTrace ?? StackTrace.current,
      ),
    };
    return result;
  }
}

/// In-app history of the signed-in user, most recent first.
@riverpod
Stream<List<AppNotification>> notificationFeed(Ref ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(const []);
  return ref.watch(notificationRepositoryProvider).watchNotifications(user.id);
}

/// Drives the dot on every bell button.
@riverpod
int unreadNotificationCount(Ref ref) =>
    ref.watch(notificationFeedProvider).value?.where((n) => !n.isRead).length ??
    0;

@riverpod
class NotificationFeedController extends _$NotificationFeedController {
  @override
  FutureOr<void> build() {}

  Future<Result<void>> markRead(AppNotification notification) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return const Err(AuthFailure.notSignedIn());
    if (notification.isRead) return const Ok(null);
    return ref
        .read(notificationRepositoryProvider)
        .markRead(userId: user.id, notificationId: notification.id);
  }

  Future<Result<void>> markAllRead() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return const Err(AuthFailure.notSignedIn());
    // Nothing unread in the feed: skip the round trip. The server statement
    // itself does not depend on the ids shown (see the repository).
    final feed = ref.read(notificationFeedProvider).value;
    if (feed != null && feed.every((n) => n.isRead)) return const Ok(null);
    return ref
        .read(notificationRepositoryProvider)
        .markAllRead(userId: user.id);
  }

  Future<Result<void>> delete(AppNotification notification) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return const Err(AuthFailure.notSignedIn());
    return ref
        .read(notificationRepositoryProvider)
        .deleteNotification(userId: user.id, notificationId: notification.id);
  }
}

/// The push pipeline on the device, driven by the session.
///
/// * signed in → ask permission, register the FCM token under the user
///   (`public.register_device`), keep it registered on refresh;
/// * signed out → invalidate the token (see
///   [PushMessagingDataSource.deleteToken]);
/// * foreground message → shown as a local notification;
/// * tap (foreground, background or cold start) → [NotificationRoute].
///
/// Why sign-out does not delete the `devices` row: this provider learns of
/// the sign-out from [currentUserProvider], i.e. once the session is already
/// gone, and RLS refuses an anonymous delete. Invalidating the token needs no
/// session and is enough on its own: FCM answers `UNREGISTERED` to the next
/// send and the worker forgets the row (`devices_forget_tokens`). If the
/// device is offline and the invalidation fails, the next account signing in
/// on the phone gets the same token, and `register_device` moves it away from
/// the previous account. The row is keyed by installation, so the same
/// person signing in again replaces the dead token in place.
///
/// Watched once by `EventHubApp`; kept alive for the app's lifetime. Web is
/// excluded on purpose: web push needs a VAPID key and a service worker.
@Riverpod(keepAlive: true)
class PushNotifications extends _$PushNotifications {
  final _subscriptions = <StreamSubscription<Object?>>[];
  StreamSubscription<String>? _tokenRefresh;
  String? _userId;

  @override
  void build() {
    // Web push needs a VAPID key (Firebase console → Cloud Messaging → Web
    // Push certificates) and web/firebase-messaging-sw.js. Without the key,
    // the web build simply does not register for pushes.
    if (kIsWeb && ref.read(appConfigProvider).webPushVapidKey.isEmpty) return;
    ref.onDispose(() {
      for (final s in _subscriptions) {
        unawaited(s.cancel());
      }
      unawaited(_tokenRefresh?.cancel());
    });

    final messaging = ref.read(pushMessagingProvider);
    final local = ref.read(localNotificationsProvider);

    // On the web the browser shows foreground pushes only through the
    // service worker; the in-app history covers them instead.
    if (!kIsWeb) {
      unawaited(local.initialize(onTap: _open));
      _subscriptions.add(messaging.onMessage.listen(local.show));
    }
    _subscriptions.add(
      messaging.onMessageOpenedApp.listen((m) => _open(m.data)),
    );
    unawaited(messaging.getInitialMessage().then(_openInitial));

    ref.listen<AppUser?>(
      currentUserProvider,
      (_, user) => unawaited(_onUserChanged(user)),
      fireImmediately: true,
    );
  }

  Future<void> _onUserChanged(AppUser? user) async {
    if (user?.id == _userId) return;
    final previous = _userId;
    _userId = user?.id;
    await _tokenRefresh?.cancel();
    _tokenRefresh = null;

    final messaging = ref.read(pushMessagingProvider);
    try {
      if (user == null) {
        if (previous != null) await messaging.deleteToken();
        return;
      }
      if (!await messaging.requestPermission()) {
        AppLogger.info('Push permission denied: device not registered');
        return;
      }
      final vapidKey = ref.read(appConfigProvider).webPushVapidKey;
      final token = await messaging.getToken(
        vapidKey: kIsWeb ? vapidKey : null,
      );
      if (token != null) await _register(user.id, token);
      _tokenRefresh = messaging.onTokenRefresh.listen(
        (token) => unawaited(_register(user.id, token)),
      );
    } catch (error, stack) {
      // Push is a convenience: a failure here must never break sign-in.
      AppLogger.error('Push setup failed', error: error, stackTrace: stack);
    }
  }

  Future<void> _register(String userId, String token) async {
    final result = await ref
        .read(notificationRepositoryProvider)
        .registerDevice(
          userId: userId,
          token: token,
          // Values of the Postgres enum `device_platform`.
          platform: kIsWeb
              ? 'web'
              : defaultTargetPlatform == TargetPlatform.iOS
              ? 'ios'
              : 'android',
        );
    if (result case Err(:final failure)) {
      AppLogger.warning('Device registration failed', error: failure);
    }
  }

  void _openInitial(RemoteMessage? message) {
    if (message != null) _open(message.data);
  }

  void _open(Map<String, Object?> data) {
    final location = NotificationRoute.locationFor(data);
    if (location == null) return;
    unawaited(ref.read(appRouterProvider).push(location));
  }
}
