import 'dart:async';

import 'package:eventhub/app/app.dart';
import 'package:eventhub/core/config/app_config.dart';
import 'package:eventhub/core/config/flavor.dart';
import 'package:eventhub/core/utils/app_logger.dart';
import 'package:eventhub/core/utils/date_formats.dart';
import 'package:eventhub/core/widgets/bootstrap_error_app.dart';
import 'package:eventhub/features/notifications/data/push_messaging_data_source.dart';
import 'package:eventhub/firebase_options.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Shared startup sequence for every flavor entrypoint.
///
/// Firebase is not optional: there is no simulated backend to fall back to.
/// If it cannot be initialised, the app shows an explicit error screen
/// instead of pretending to work. App Check and Crashlytics are best
/// effort: a failure there is logged and never blocks the app.
Future<void> bootstrap(Flavor flavor) async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.fromFlavor(flavor);

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    AppLogger.error(
      'Flutter error',
      error: details.exception,
      stackTrace: details.stack,
      fatal: true,
    );
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.error(
      'Uncaught error',
      error: error,
      stackTrace: stack,
      fatal: true,
    );
    return true;
  };

  await initializeDateFormatting(AppDateFormats.locale);

  Object? startupError;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await _activateAppCheck(config);
    if (!kIsWeb) {
      await _enableCrashReporting();
      // Must be registered from the main isolate, before any other
      // messaging call. Web push goes through web/firebase-messaging-sw.js.
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    }
  } catch (error, stack) {
    AppLogger.error('Firebase init failed', error: error, stackTrace: stack);
    startupError = error;
  }

  AppLogger.info('Starting ${config.appName} [${flavor.name}]');

  runApp(
    ProviderScope(
      overrides: [appConfigProvider.overrideWithValue(config)],
      child: startupError == null
          ? const EventHubApp()
          : BootstrapErrorApp(error: startupError),
    ),
  );
}

/// Attests that requests come from the genuine app.
///
/// Release builds use Play Integrity (Android) and App Attest with a
/// DeviceCheck fallback (Apple). Debug builds use the debug providers: the
/// debug token printed in the device logs must be registered once in the
/// Firebase console (App Check → Apps → Manage debug tokens). The web needs a
/// reCAPTCHA v3 site key, without which it is simply not activated.
Future<void> _activateAppCheck(AppConfig config) async {
  if (kIsWeb && config.appCheckWebSiteKey.isEmpty) return;
  try {
    await FirebaseAppCheck.instance.activate(
      providerAndroid: kReleaseMode
          ? const AndroidPlayIntegrityProvider()
          : const AndroidDebugProvider(),
      providerApple: kReleaseMode
          ? const AppleAppAttestWithDeviceCheckFallbackProvider()
          : const AppleDebugProvider(),
      providerWeb: kIsWeb
          ? ReCaptchaV3Provider(config.appCheckWebSiteKey)
          : null,
    );
  } catch (error, stack) {
    AppLogger.error(
      'App Check activation failed',
      error: error,
      stackTrace: stack,
    );
  }
}

/// Crashlytics collects in profile/release only: debug crashes are the
/// developer's console, not production statistics.
Future<void> _enableCrashReporting() async {
  try {
    final crashlytics = FirebaseCrashlytics.instance;
    await crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);
    AppLogger.reporter = (error, stack, {required fatal, reason}) {
      unawaited(
        crashlytics.recordError(error, stack, fatal: fatal, reason: reason),
      );
    };
  } catch (error) {
    AppLogger.warning('Crashlytics unavailable', error: error);
  }
}
