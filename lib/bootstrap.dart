import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventhub/app/app.dart';
import 'package:eventhub/core/config/app_config.dart';
import 'package:eventhub/core/config/flavor.dart';
import 'package:eventhub/core/utils/app_logger.dart';
import 'package:eventhub/core/utils/date_formats.dart';
import 'package:eventhub/core/widgets/bootstrap_error_app.dart';
import 'package:eventhub/features/notifications/data/push_messaging_data_source.dart';
import 'package:eventhub/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Séquence de démarrage commune à tous les points d'entrée de flavor.
///
/// Firebase *est* le backend : Authentication, Cloud Firestore, FCM,
/// Crashlytics et Analytics. Il n'est pas optionnel — il n'existe aucun
/// backend simulé sur lequel se rabattre — donc un échec affiche un écran
/// d'erreur explicite au lieu de faire semblant de fonctionner.
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
    await _configureFirestore(config);
    if (_supportsMobileServices) {
      await _enableCrashReporting();
      // Doit être enregistré depuis l'isolat principal, avant tout autre
      // appel de messagerie. Le push web, lui, passe par
      // web/firebase-messaging-sw.js.
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

/// Crashlytics et le FCM en arrière-plan n'existent que sur Android, iOS et
/// macOS.
bool get _supportsMobileServices =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS);

/// Cache hors ligne sur toutes les plateformes — le SDK web le laisse désactivé
/// par défaut — dimensionné pour qu'un long catalogue ne chasse pas du cache
/// les billets dont on a besoin à la porte, sans réseau.
Future<void> _configureFirestore(AppConfig config) async {
  final firestore = FirebaseFirestore.instance;
  if (config.useEmulator) {
    firestore.useFirestoreEmulator(config.emulatorHost, 8080);
    await FirebaseAuth.instance.useAuthEmulator(config.emulatorHost, 9099);
    AppLogger.warning('Using the Firebase emulators on ${config.emulatorHost}');
  }
  firestore.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: 100 * 1024 * 1024,
  );
}

/// Crashlytics ne collecte qu'en profile et en release : un plantage en debug
/// appartient à la console du développeur, pas aux statistiques de production.
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
