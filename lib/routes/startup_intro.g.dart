// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'startup_intro.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(StartupIntro)
final startupIntroProvider = StartupIntroProvider._();

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
final class StartupIntroProvider extends $NotifierProvider<StartupIntro, bool> {
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
  StartupIntroProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'startupIntroProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$startupIntroHash();

  @$internal
  @override
  StartupIntro create() => StartupIntro();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$startupIntroHash() => r'e53b280221e0fc64496437d60b8d4d16dcd54881';

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

abstract class _$StartupIntro extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
