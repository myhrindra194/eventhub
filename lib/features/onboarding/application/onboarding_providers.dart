import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'onboarding_providers.g.dart';

/// Whether the onboarding carousel has already been shown on this install.
///
/// Persisted with `SharedPreferences`, i.e. survives restarts and updates and
/// is only reset when the app is uninstalled (product requirement).
@Riverpod(keepAlive: true)
class OnboardingSeen extends _$OnboardingSeen {
  static const _key = 'onboarding_seen_v1';

  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
    state = const AsyncData(true);
  }
}
