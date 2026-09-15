import 'dart:async';

import 'package:eventhub/app/app.dart';
import 'package:eventhub/core/config/app_config.dart';
import 'package:eventhub/core/config/flavor.dart';
import 'package:eventhub/core/utils/app_logger.dart';
import 'package:eventhub/core/utils/date_formats.dart';
import 'package:eventhub/core/widgets/bootstrap_error_app.dart';
import 'package:eventhub/features/notifications/data/push_messaging_data_source.dart';
import 'package:eventhub/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Shared startup sequence for every flavor entrypoint.
///
/// Supabase is the backend (data, auth, storage, server logic); Firebase
/// delivers push notifications and collects crash reports and analytics.
/// Neither is optional: there is no simulated backend to fall back to, so a
/// failure shows an explicit error screen instead of pretending to work.
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
    if (!config.hasBackend) {
      throw StateError(
        'Configuration Supabase manquante : lancez l’app avec '
        '--dart-define=SUPABASE_URL=… et --dart-define=SUPABASE_ANON_KEY=…',
      );
    }
    await Supabase.initialize(
      url: config.supabaseUrl,
      // Auth uses PKCE (the default): confirmation and recovery links come
      // back to the app as a one-time code, never as tokens in a URL.
      publishableKey: config.supabaseAnonKey,
      debug: kDebugMode && flavor == Flavor.dev,
    );

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (!kIsWeb) {
      await _enableCrashReporting();
      // Must be registered from the main isolate, before any other
      // messaging call. Web push goes through web/firebase-messaging-sw.js.
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    }
  } catch (error, stack) {
    AppLogger.error('Backend init failed', error: error, stackTrace: stack);
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
