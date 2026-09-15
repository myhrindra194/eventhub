import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Receives errors worth reporting to a crash-reporting backend.
typedef ErrorReporter =
    void Function(
      Object error,
      StackTrace? stackTrace, {
      required bool fatal,
      String? reason,
    });

/// Thin logging facade over `dart:developer`.
///
/// Errors are also forwarded to [reporter] when one is installed —
/// `bootstrap()` plugs Crashlytics in on mobile. The facade itself imports no
/// SDK, so every layer (and every test) can log without Firebase.
abstract final class AppLogger {
  static const _name = 'EventHub';

  /// Crash-reporting sink; `null` in tests and on the web.
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

  /// [fatal] marks crashes (uncaught Flutter/platform errors) as opposed to
  /// handled failures, which Crashlytics groups separately.
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
