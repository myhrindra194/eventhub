import 'package:eventhub/core/config/flavor.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_config.g.dart';

/// Immutable runtime configuration derived from the [Flavor].
///
/// There is no simulated backend: every flavor talks to the Firebase project
/// described by `lib/firebase_options.dart`. For development against
/// disposable data, start the emulators (`make emulators`) and run with
/// `--dart-define=USE_FIREBASE_EMULATOR=true`.
@immutable
class AppConfig {
  const AppConfig({
    required this.flavor,
    required this.appName,
    this.useEmulator = const bool.fromEnvironment('USE_FIREBASE_EMULATOR'),
    this.emulatorHost = const String.fromEnvironment(
      'FIREBASE_EMULATOR_HOST',
      defaultValue: 'localhost',
    ),
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
    ),
    Flavor.staging => const AppConfig(
      flavor: Flavor.staging,
      appName: 'EventHub (staging)',
    ),
    Flavor.prod => const AppConfig(flavor: Flavor.prod, appName: 'EventHub'),
  };

  final Flavor flavor;
  final String appName;

  /// Talk to the local Auth (9099) and Firestore (8080) emulators instead of
  /// the cloud project. Never set for a release build.
  final bool useEmulator;

  /// Host of the emulators: `localhost` on desktop, web and the iOS
  /// simulator; `10.0.2.2` from the Android emulator; the computer's LAN
  /// address from a physical phone.
  final String emulatorHost;

  /// Delay tolerated between account creation and its profile document
  /// before the session is reported as `ProfileMissing`.
  final Duration profileGracePeriod;

  /// OAuth *web* client id of the Firebase project, which native Google
  /// Sign-In on Android needs to obtain an ID token Firebase Auth accepts
  /// (`--dart-define=GOOGLE_SERVER_CLIENT_ID=…apps.googleusercontent.com`).
  /// Empty → the Google button is hidden on Android rather than failing.
  final String googleServerClientId;

  /// Public "Web Push certificate" key of the Firebase project
  /// (`--dart-define=FIREBASE_WEB_VAPID_KEY=…`). Empty → no web push token.
  final String webPushVapidKey;

  /// Google Sign-In needs no extra configuration on the web (Firebase popup)
  /// and on iOS (client id in Info.plist); Android needs
  /// [googleServerClientId]. Desktop has no Google provider in FlutterFire.
  bool get isGoogleSignInAvailable =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      (defaultTargetPlatform == TargetPlatform.android &&
          googleServerClientId.isNotEmpty);
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
