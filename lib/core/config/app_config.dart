import 'package:eventhub/core/config/flavor.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_config.g.dart';

/// Immutable runtime configuration derived from the [Flavor].
///
/// There is no simulated backend: every flavor talks to a Supabase project,
/// given at build time (`--dart-define=SUPABASE_URL=…` and
/// `--dart-define=SUPABASE_ANON_KEY=…`). Point them at a local stack
/// (`supabase start`) for development against disposable data.
@immutable
class AppConfig {
  const AppConfig({
    required this.flavor,
    required this.appName,
    this.supabaseUrl = const String.fromEnvironment('SUPABASE_URL'),
    this.supabaseAnonKey = const String.fromEnvironment('SUPABASE_ANON_KEY'),
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

  /// Where Supabase Auth sends people back to the app: email confirmation,
  /// password reset. Declared in `supabase/config.toml`
  /// (`additional_redirect_urls`) and as an intent filter in
  /// AndroidManifest.xml.
  static const authRedirectUrl = 'eventhub://auth-callback';

  final Flavor flavor;
  final String appName;

  /// `https://<project-ref>.supabase.co`.
  final String supabaseUrl;

  /// The project's public (anon) key. Safe to ship: it grants nothing that
  /// Row Level Security does not allow a signed-in user.
  final String supabaseAnonKey;

  /// Delay tolerated between account creation and its profile row before
  /// the session is reported as `ProfileMissing`.
  final Duration profileGracePeriod;

  /// OAuth *web* client id of the Google Cloud project, required by native
  /// Google Sign-In to obtain an ID token that Supabase Auth accepts
  /// (`--dart-define=GOOGLE_SERVER_CLIENT_ID=…apps.googleusercontent.com`).
  /// Empty → the Google button is hidden on Android rather than failing.
  final String googleServerClientId;

  /// Public "Web Push certificate" key of the Firebase project, which still
  /// delivers push notifications (`--dart-define=FIREBASE_WEB_VAPID_KEY=…`).
  /// Empty → no web push.
  final String webPushVapidKey;

  bool get hasBackend => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Google Sign-In needs no extra configuration on the web (OAuth redirect)
  /// and on iOS (client id in Info.plist); Android needs
  /// [googleServerClientId].
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
