import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Thin logging facade over `dart:developer`. Swap the sink here (Crashlytics,
/// Sentry...) without touching call sites.
abstract final class AppLogger {
  static const _name = 'EventHub';

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

  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? tag,
  }) {
    developer.log(
      message,
      name: tag ?? _name,
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
