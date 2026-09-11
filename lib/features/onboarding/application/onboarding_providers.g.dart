// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the onboarding carousel has already been shown on this install.
///
/// Persisted with `SharedPreferences`, i.e. survives restarts and updates and
/// is only reset when the app is uninstalled (product requirement).

@ProviderFor(OnboardingSeen)
final onboardingSeenProvider = OnboardingSeenProvider._();

/// Whether the onboarding carousel has already been shown on this install.
///
/// Persisted with `SharedPreferences`, i.e. survives restarts and updates and
/// is only reset when the app is uninstalled (product requirement).
final class OnboardingSeenProvider
    extends $AsyncNotifierProvider<OnboardingSeen, bool> {
  /// Whether the onboarding carousel has already been shown on this install.
  ///
  /// Persisted with `SharedPreferences`, i.e. survives restarts and updates and
  /// is only reset when the app is uninstalled (product requirement).
  OnboardingSeenProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onboardingSeenProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onboardingSeenHash();

  @$internal
  @override
  OnboardingSeen create() => OnboardingSeen();
}

String _$onboardingSeenHash() => r'9d9e930ed45c8b6711d3bb9e3fa6be062965aba0';

/// Whether the onboarding carousel has already been shown on this install.
///
/// Persisted with `SharedPreferences`, i.e. survives restarts and updates and
/// is only reset when the app is uninstalled (product requirement).

abstract class _$OnboardingSeen extends $AsyncNotifier<bool> {
  FutureOr<bool> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<bool>, bool>,
              AsyncValue<bool>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
