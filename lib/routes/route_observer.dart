import 'package:eventhub/core/utils/app_logger.dart';
import 'package:flutter/widgets.dart';

/// Navigation telemetry.
///
/// Every push/pop/replace is logged with a stable screen name, which is the
/// exact hook an analytics or crash-reporting SDK needs (`setCurrentScreen`,
/// breadcrumbs). Keeping it in the routing layer means feature code never
/// has to remember to instrument navigation.
class AppRouteObserver extends NavigatorObserver {
  AppRouteObserver({this.onScreen});

  /// Optional sink — wire it to Analytics/Crashlytics in `bootstrap()`.
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
