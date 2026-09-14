import 'package:eventhub/core/config/flavor.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_config.g.dart';

/// Immutable runtime configuration derived from the [Flavor].
///
/// There is no simulated backend: every flavor talks to Firebase. Local
/// development against fake data goes through the emulator suite
/// (`USE_EMULATORS=true`), which runs the real security rules.
@immutable
class AppConfig {
  const AppConfig({
    required this.flavor,
    required this.appName,
    required this.useFirebaseEmulators,
    this.emulatorHost = '10.0.2.2',
    this.profileGracePeriod = const Duration(seconds: 3),
    this.googleServerClientId = const String.fromEnvironment(
      'GOOGLE_SERVER_CLIENT_ID',
    ),
    this.webPushVapidKey = const String.fromEnvironment(
      'FIREBASE_WEB_VAPID_KEY',
    ),
  });

  factory AppConfig.fromFlavor(Flavor flavor) => switch (flavor) {
    Flavor.dev => const AppConfig(
      flavor: Flavor.dev,
      appName: 'EventHub (dev)',
      useFirebaseEmulators: bool.fromEnvironment('USE_EMULATORS'),
    ),
    Flavor.staging => const AppConfig(
      flavor: Flavor.staging,
      appName: 'EventHub (staging)',
      useFirebaseEmulators: false,
    ),
    Flavor.prod => const AppConfig(
      flavor: Flavor.prod,
      appName: 'EventHub',
      useFirebaseEmulators: false,
    ),
  };

  /// Region of the callable Cloud Functions. Must equal `REGION` in
  /// `functions/src/index.ts`, itself aligned on the Firestore location
  /// (`nam5` → `us-central1`).
  static const functionsRegion = 'us-central1';

  final Flavor flavor;
  final String appName;

  /// When true, Auth/Firestore/Storage/Functions use the local emulators.
  final bool useFirebaseEmulators;

  /// Host used to reach the emulators (10.0.2.2 = host loopback from the
  /// Android emulator; use the machine LAN IP for a physical device).
  final String emulatorHost;

  /// Delay tolerated between Firebase user creation and the Firestore profile
  /// write before the session is reported as `ProfileMissing`.
  final Duration profileGracePeriod;

  /// OAuth *web* client id of the Firebase project, required by Google
  /// Sign-In on Android to obtain an ID token
  /// (`--dart-define=GOOGLE_SERVER_CLIENT_ID=…apps.googleusercontent.com`).
  /// Empty → the Google button is hidden on Android rather than failing.
  final String googleServerClientId;

  /// Public "Web Push certificate" key of the project
  /// (`--dart-define=FIREBASE_WEB_VAPID_KEY=…`). Empty → no web push.
  final String webPushVapidKey;

  /// reCAPTCHA v3 site key registered for App Check on the web
  /// (`--dart-define=APP_CHECK_RECAPTCHA_SITE_KEY=…`). Empty → App Check is
  /// not activated on the web.
  String get appCheckWebSiteKey =>
      const String.fromEnvironment('APP_CHECK_RECAPTCHA_SITE_KEY');

  /// Google Sign-In needs no extra configuration on the web (popup) and on
  /// iOS (client id in Info.plist); Android needs [googleServerClientId].
  bool get isGoogleSignInAvailable =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      googleServerClientId.isNotEmpty;
}

/// Must be overridden in `bootstrap()`; the default throws on purpose so a
/// missing override is caught immediately instead of silently using dev.
@Riverpod(keepAlive: true)
AppConfig appConfig(Ref ref) =>
    throw StateError('appConfigProvider must be overridden in bootstrap()');

/// Injectable clock. Override in tests to freeze time.
typedef Clock = DateTime Function();

@Riverpod(keepAlive: true)
Clock clock(Ref ref) => DateTime.now;
