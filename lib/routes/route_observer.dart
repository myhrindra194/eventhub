import 'package:eventhub/core/utils/app_logger.dart';
import 'package:flutter/widgets.dart';

/// Télémétrie de navigation.
///
/// Chaque push/pop/replace est journalisé avec un nom d’écran stable, ce qui
/// est exactement le point d’accroche attendu par un SDK d’analytics ou de
/// crash reporting (`setCurrentScreen`, fils d’Ariane). Le garder dans la
/// couche de routage évite au code des features d’avoir à penser à
/// instrumenter la navigation.
class AppRouteObserver extends NavigatorObserver {
  AppRouteObserver({this.onScreen});

  /// Puits optionnel — à brancher sur Analytics/Crashlytics dans
  /// `bootstrap()`.
  final void Function(String screen)? onScreen;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _report('push', route);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _report('pop', previousRoute);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _report('replace', newRoute);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _report('remove', previousRoute);

  void _report(String action, Route<dynamic>? route) {
    final name = route?.settings.name;
    if (name == null || name.isEmpty) return;
    AppLogger.debug('nav.$action → $name', tag: 'Router');
    onScreen?.call(name);
  }
}
