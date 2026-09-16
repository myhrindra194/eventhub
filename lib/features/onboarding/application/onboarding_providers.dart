import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'onboarding_providers.g.dart';

/// Indique si le carrousel d’onboarding a déjà été affiché sur cette
/// installation.
///
/// Persisté via `SharedPreferences` : il survit donc aux redémarrages comme
/// aux mises à jour et n’est remis à zéro qu’à la désinstallation de
/// l’application (exigence produit).
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
