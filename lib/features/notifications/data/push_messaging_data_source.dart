import 'package:firebase_messaging/firebase_messaging.dart';

/// Called by FCM in a background isolate when a message arrives while the
/// app is not in the foreground.
///
/// Every message the `worker` Edge Function sends carries a `notification`
/// block,
/// which Android and iOS display themselves in that state — so there is
/// nothing to render here. The handler must still exist and be registered
/// (see `bootstrap.dart`), otherwise data-only messages are dropped.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

/// Thin wrapper over [FirebaseMessaging], so the application layer can be
/// tested without the plugin.
class PushMessagingDataSource {
  const PushMessagingDataSource(this._messaging);

  final FirebaseMessaging _messaging;

  /// Shows the system prompt (Android 13+, iOS) once; afterwards returns the
  /// stored decision without prompting again.
  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission();
    return switch (settings.authorizationStatus) {
      AuthorizationStatus.authorized || AuthorizationStatus.provisional => true,
      AuthorizationStatus.denied ||
      AuthorizationStatus.deniedPermanently ||
      AuthorizationStatus.notDetermined => false,
    };
  }

  /// [vapidKey] is required on the web, ignored elsewhere.
  Future<String?> getToken({String? vapidKey}) =>
      _messaging.getToken(vapidKey: vapidKey);

  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  /// Messages received while the app is in the foreground (not displayed by
  /// the system).
  Stream<RemoteMessage> get onMessage => FirebaseMessaging.onMessage;

  /// A notification tapped while the app was in the background.
  Stream<RemoteMessage> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp;

  /// The notification that launched the app from a terminated state, if any.
  Future<RemoteMessage?> getInitialMessage() => _messaging.getInitialMessage();

  /// Invalidates this device's token. Called on sign-out so the next person
  /// signing in on the same phone never receives the previous user's pushes:
  /// the next send to the old token is answered `UNREGISTERED` and the worker
  /// deletes the stale `devices` row (`devices_forget_tokens`).
  Future<void> deleteToken() => _messaging.deleteToken();
}
