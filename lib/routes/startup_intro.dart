import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'startup_intro.g.dart';

/// Vrai une fois que l'animation du démarrage a été vue en entier.
///
/// **Pourquoi le router l'attend.** Sans cette porte, l'écran de démarrage
/// dure exactement le temps de lire la session : quelques dizaines de
/// millisecondes quand elle est en cache. La marque apparaît alors en un
/// éclair et disparaît au milieu de son tracé — c'est précisément ce qui
/// donne l'impression d'une animation « sale ». En retenant le splash jusqu'à
/// la fin de l'intro (≈ 1,3 s), chaque démarrage raconte la même courte
/// séquence, puis la suite arrive en fondu.
///
/// **Garde-fou.** Le splash signale lui-même la fin de son animation. Si,
/// pour une raison quelconque, il n'en avait pas l'occasion, le minuteur de
/// secours libère le démarrage : une animation ne doit jamais pouvoir bloquer
/// l'accès à l'app.
@Riverpod(keepAlive: true)
class StartupIntro extends _$StartupIntro {
  /// Au-delà, l'intro est considérée comme terminée quoi qu'il arrive.
  static const fallback = Duration(milliseconds: 2400);

  Timer? _fallback;

  @override
  bool build() {
    _fallback = Timer(fallback, complete);
    ref.onDispose(() => _fallback?.cancel());
    return false;
  }

  void complete() {
    _fallback?.cancel();
    if (!state) state = true;
  }
}
