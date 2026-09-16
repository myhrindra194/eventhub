// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Apparence choisie par l’utilisateur, persistée d’un lancement à l’autre.
///
/// Valeur par défaut : [ThemeMode.system]. Respecter le réglage de l’OS est
/// le choix mature — l’interrupteur dans l’app existe pour la minorité qui
/// veut le surcharger, pas comme mécanisme principal.

@ProviderFor(ThemeModeController)
final themeModeControllerProvider = ThemeModeControllerProvider._();

/// Apparence choisie par l’utilisateur, persistée d’un lancement à l’autre.
///
/// Valeur par défaut : [ThemeMode.system]. Respecter le réglage de l’OS est
/// le choix mature — l’interrupteur dans l’app existe pour la minorité qui
/// veut le surcharger, pas comme mécanisme principal.
final class ThemeModeControllerProvider
    extends $NotifierProvider<ThemeModeController, ThemeMode> {
  /// Apparence choisie par l’utilisateur, persistée d’un lancement à l’autre.
  ///
  /// Valeur par défaut : [ThemeMode.system]. Respecter le réglage de l’OS est
  /// le choix mature — l’interrupteur dans l’app existe pour la minorité qui
  /// veut le surcharger, pas comme mécanisme principal.
  ThemeModeControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'themeModeControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$themeModeControllerHash();

  @$internal
  @override
  ThemeModeController create() => ThemeModeController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ThemeMode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ThemeMode>(value),
    );
  }
}

String _$themeModeControllerHash() =>
    r'54d9a7257060b3e1fe63748370025d771cd7fb91';

/// Apparence choisie par l’utilisateur, persistée d’un lancement à l’autre.
///
/// Valeur par défaut : [ThemeMode.system]. Respecter le réglage de l’OS est
/// le choix mature — l’interrupteur dans l’app existe pour la minorité qui
/// veut le surcharger, pas comme mécanisme principal.

abstract class _$ThemeModeController extends $Notifier<ThemeMode> {
  ThemeMode build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ThemeMode, ThemeMode>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ThemeMode, ThemeMode>,
              ThemeMode,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
