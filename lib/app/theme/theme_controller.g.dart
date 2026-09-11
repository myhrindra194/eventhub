// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// User-selected appearance, persisted across launches.
///
/// Defaults to [ThemeMode.system]: respecting the OS setting is the mature
/// default — the in-app switch exists for the minority who want to override
/// it, not as the primary mechanism.

@ProviderFor(ThemeModeController)
final themeModeControllerProvider = ThemeModeControllerProvider._();

/// User-selected appearance, persisted across launches.
///
/// Defaults to [ThemeMode.system]: respecting the OS setting is the mature
/// default — the in-app switch exists for the minority who want to override
/// it, not as the primary mechanism.
final class ThemeModeControllerProvider
    extends $NotifierProvider<ThemeModeController, ThemeMode> {
  /// User-selected appearance, persisted across launches.
  ///
  /// Defaults to [ThemeMode.system]: respecting the OS setting is the mature
  /// default — the in-app switch exists for the minority who want to override
  /// it, not as the primary mechanism.
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

/// User-selected appearance, persisted across launches.
///
/// Defaults to [ThemeMode.system]: respecting the OS setting is the mature
/// default — the in-app switch exists for the minority who want to override
/// it, not as the primary mechanism.

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
