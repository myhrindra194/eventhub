import 'dart:async';
import 'dart:ui';

import 'package:eventhub/app/app.dart';
import 'package:eventhub/core/config/app_config.dart';
import 'package:eventhub/core/config/flavor.dart';
import 'package:eventhub/core/utils/app_logger.dart';
import 'package:eventhub/core/utils/date_formats.dart';
import 'package:eventhub/core/widgets/bootstrap_error_app.dart';
import 'package:eventhub/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Shared startup sequence for every flavor entrypoint.
Future<void> bootstrap(Flavor flavor) async {
  WidgetsFlutterBinding.ensureInitialized();
  var config = AppConfig.fromFlavor(flavor);

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    AppLogger.error(
      'Flutter error',
      error: details.exception,
      stackTrace: details.stack,
    );
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.error('Uncaught error', error: error, stackTrace: stack);
    return true;
  };

  await initializeDateFormatting(AppDateFormats.locale);

  Object? startupError;
  if (config.useMockBackend) {
    AppLogger.info('MOCK backend enabled: Firebase initialisation skipped');
  } else {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (error, stack) {
      AppLogger.error('Firebase init failed', error: error, stackTrace: stack);
      if (flavor.isProd) {
        // Production must never silently run on fake data: show an
        // actionable screen instead of a red box.
        startupError = error;
      } else {
        // Developer convenience: without `flutterfire configure`, dev and
        // staging fall back to the in-memory backend so the product can be
        // exercised end to end. The login screen shows the demo accounts.
        AppLogger.warning(
          'Falling back to the MOCK backend (flavor ${flavor.name}). '
          'Run `flutterfire configure` to use Firebase.',
        );
        config = config.copyWith(useMockBackend: true);
      }
    }
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
