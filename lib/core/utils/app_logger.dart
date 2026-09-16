import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Reçoit les erreurs qui méritent d’être remontées à un backend de crash
/// reporting.
typedef ErrorReporter =
    void Function(
      Object error,
      StackTrace? stackTrace, {
      required bool fatal,
      String? reason,
    });

/// Fine façade de journalisation au-dessus de `dart:developer`.
///
/// Les erreurs sont également transmises à [reporter] lorsqu’un reporter est
/// installé — `bootstrap()` y branche Crashlytics sur mobile. La façade
/// elle-même n’importe aucun SDK : toutes les couches (et tous les tests)
/// peuvent donc journaliser sans Firebase.
abstract final class AppLogger {
  static const _name = 'EventHub';

  /// Puits de crash reporting ; `null` dans les tests et sur le web.
  static ErrorReporter? reporter;

  static void debug(String message, {String? tag}) {
    if (kDebugMode) {
      developer.log(message, name: tag ?? _name, level: 500);
    }
  }

  static void info(String message, {String? tag}) {
    developer.log(message, name: tag ?? _name, level: 800);
  }

  static void warning(String message, {Object? error, String? tag}) {
    developer.log(message, name: tag ?? _name, level: 900, error: error);
  }

  /// [fatal] distingue les crashs (erreurs Flutter ou plateforme non
  /// interceptées) des échecs traités, que Crashlytics regroupe à part.
  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? tag,
    bool fatal = false,
  }) {
    developer.log(
      message,
      name: tag ?? _name,
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
    if (error != null) {
      reporter?.call(error, stackTrace, fatal: fatal, reason: message);
    }
  }
}
