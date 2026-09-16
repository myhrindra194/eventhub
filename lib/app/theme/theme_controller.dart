import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'theme_controller.g.dart';

/// Apparence choisie par l’utilisateur, persistée d’un lancement à l’autre.
///
/// Valeur par défaut : [ThemeMode.system]. Respecter le réglage de l’OS est
/// le choix mature — l’interrupteur dans l’app existe pour la minorité qui
/// veut le surcharger, pas comme mécanisme principal.
@Riverpod(keepAlive: true)
class ThemeModeController extends _$ThemeModeController {
  static const _key = 'theme_mode_v1';

  @override
  ThemeMode build() {
    // Lecture asynchrone, puis mise à jour de l’état dès qu’elle aboutit ;
    // l’app ne doit pas bloquer sa première frame sur un accès disque.
    Future.microtask(_restore);
    return ThemeMode.system;
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_key);
    final restored = ThemeMode.values
        .where((m) => m.name == stored)
        .firstOrNull;
    if (restored != null && restored != state) state = restored;
  }

  Future<void> set(ThemeMode mode) async {
    if (mode == state) return;
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }

  /// Raccourci pour un interrupteur à deux états dans l’UI.
  Future<void> toggle(BuildContext context) {
    final effective = switch (state) {
      ThemeMode.system =>
        MediaQuery.platformBrightnessOf(context) == Brightness.dark
            ? ThemeMode.dark
            : ThemeMode.light,
      final mode => mode,
    };
    return set(effective == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }
}

extension ThemeModeLabel on ThemeMode {
  String get label => switch (this) {
    ThemeMode.system => 'Automatique',
    ThemeMode.light => 'Clair',
    ThemeMode.dark => 'Sombre',
  };

  String get description => switch (this) {
    ThemeMode.system => "Suit le réglage de l'appareil",
    ThemeMode.light => 'Toujours en thème clair',
    ThemeMode.dark => 'Toujours en thème sombre',
  };

  IconData get icon => switch (this) {
    ThemeMode.system => Icons.brightness_auto_rounded,
    ThemeMode.light => Icons.light_mode_rounded,
    ThemeMode.dark => Icons.dark_mode_rounded,
  };
}
