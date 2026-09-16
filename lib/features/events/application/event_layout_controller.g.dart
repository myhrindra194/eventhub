// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_layout_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Disposition choisie par l'utilisateur, persistée d'un lancement à l'autre.
///
/// Même patron que `ThemeModeController` : une valeur par défaut rendue
/// immédiatement, puis la valeur stockée appliquée dès que la lecture disque
/// aboutit. `keepAlive`, parce que l'accueil et le catalogue la lisent tour à
/// tour : un provider auto-disposé relirait le disque à chaque navigation et
/// ferait clignoter la disposition par défaut entre deux écrans.

@ProviderFor(EventLayoutController)
final eventLayoutControllerProvider = EventLayoutControllerProvider._();

/// Disposition choisie par l'utilisateur, persistée d'un lancement à l'autre.
///
/// Même patron que `ThemeModeController` : une valeur par défaut rendue
/// immédiatement, puis la valeur stockée appliquée dès que la lecture disque
/// aboutit. `keepAlive`, parce que l'accueil et le catalogue la lisent tour à
/// tour : un provider auto-disposé relirait le disque à chaque navigation et
/// ferait clignoter la disposition par défaut entre deux écrans.
final class EventLayoutControllerProvider
    extends $NotifierProvider<EventLayoutController, EventLayout> {
  /// Disposition choisie par l'utilisateur, persistée d'un lancement à l'autre.
  ///
  /// Même patron que `ThemeModeController` : une valeur par défaut rendue
  /// immédiatement, puis la valeur stockée appliquée dès que la lecture disque
  /// aboutit. `keepAlive`, parce que l'accueil et le catalogue la lisent tour à
  /// tour : un provider auto-disposé relirait le disque à chaque navigation et
  /// ferait clignoter la disposition par défaut entre deux écrans.
  EventLayoutControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'eventLayoutControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$eventLayoutControllerHash();

  @$internal
  @override
  EventLayoutController create() => EventLayoutController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EventLayout value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EventLayout>(value),
    );
  }
}

String _$eventLayoutControllerHash() =>
    r'a0304f9f679ab70cd9f4c5d3e6f320aa39b27b13';

/// Disposition choisie par l'utilisateur, persistée d'un lancement à l'autre.
///
/// Même patron que `ThemeModeController` : une valeur par défaut rendue
/// immédiatement, puis la valeur stockée appliquée dès que la lecture disque
/// aboutit. `keepAlive`, parce que l'accueil et le catalogue la lisent tour à
/// tour : un provider auto-disposé relirait le disque à chaque navigation et
/// ferait clignoter la disposition par défaut entre deux écrans.

abstract class _$EventLayoutController extends $Notifier<EventLayout> {
  EventLayout build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<EventLayout, EventLayout>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<EventLayout, EventLayout>,
              EventLayout,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
