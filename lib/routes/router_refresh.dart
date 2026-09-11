import 'package:flutter/foundation.dart';

/// Minimal [Listenable] used as GoRouter's `refreshListenable`.
///
/// The router is created once and kept alive; whenever a value the guard
/// depends on changes (session, onboarding flag), we notify instead of
/// rebuilding the router — rebuilding would reset the navigation stacks.
class RouterRefresh extends ChangeNotifier {
  void notify() => notifyListeners();
}
