// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Indique si le carrousel d’onboarding a déjà été affiché sur cette
/// installation.
///
/// Persisté via `SharedPreferences` : il survit donc aux redémarrages comme
/// aux mises à jour et n’est remis à zéro qu’à la désinstallation de
/// l’application (exigence produit).

@ProviderFor(OnboardingSeen)
final onboardingSeenProvider = OnboardingSeenProvider._();

/// Indique si le carrousel d’onboarding a déjà été affiché sur cette
/// installation.
///
/// Persisté via `SharedPreferences` : il survit donc aux redémarrages comme
/// aux mises à jour et n’est remis à zéro qu’à la désinstallation de
/// l’application (exigence produit).
final class OnboardingSeenProvider
    extends $AsyncNotifierProvider<OnboardingSeen, bool> {
  /// Indique si le carrousel d’onboarding a déjà été affiché sur cette
  /// installation.
  ///
  /// Persisté via `SharedPreferences` : il survit donc aux redémarrages comme
  /// aux mises à jour et n’est remis à zéro qu’à la désinstallation de
  /// l’application (exigence produit).
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

/// Indique si le carrousel d’onboarding a déjà été affiché sur cette
/// installation.
///
/// Persisté via `SharedPreferences` : il survit donc aux redémarrages comme
/// aux mises à jour et n’est remis à zéro qu’à la désinstallation de
/// l’application (exigence produit).

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
