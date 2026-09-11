import 'package:eventhub/core/config/flavor.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_config.g.dart';

/// Immutable runtime configuration derived from the [Flavor].
@immutable
class AppConfig {
  const AppConfig({
    required this.flavor,
    required this.appName,
    required this.useFirebaseEmulators,
    this.useMockBackend = false,
    this.emulatorHost = '10.0.2.2',
    this.profileGracePeriod = const Duration(seconds: 3),
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

  final Flavor flavor;
  final String appName;

  /// When true, Auth/Firestore/Storage are pointed to the local emulator suite.
  final bool useFirebaseEmulators;

  /// When true (`--dart-define=MOCK=true`), Firebase is never initialised and
  /// every repository is backed by the in-memory `MockStore` seeded with demo
  /// data. Lets the whole product be exercised without a Firebase project.
  final bool useMockBackend;

  /// Host used to reach the emulators (10.0.2.2 = host loopback from the
  /// Android emulator; use the machine LAN IP for a physical device).
  final String emulatorHost;

  /// Delay tolerated between Firebase user creation and the Firestore profile
  /// write before the session is reported as `ProfileMissing`.
  final Duration profileGracePeriod;

  AppConfig copyWith({bool? useMockBackend}) => AppConfig(
    flavor: flavor,
    appName: appName,
    useFirebaseEmulators: useFirebaseEmulators,
    useMockBackend: useMockBackend ?? this.useMockBackend,
    emulatorHost: emulatorHost,
    profileGracePeriod: profileGracePeriod,
  );
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
