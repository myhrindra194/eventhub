// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Pilote les actions d’authentification depuis l’UI. `state` reflète
/// l’action en cours (chargement / erreur), tandis que la session réelle,
/// elle, provient de `authSessionProvider`.

@ProviderFor(AuthController)
final authControllerProvider = AuthControllerProvider._();

/// Pilote les actions d’authentification depuis l’UI. `state` reflète
/// l’action en cours (chargement / erreur), tandis que la session réelle,
/// elle, provient de `authSessionProvider`.
final class AuthControllerProvider
    extends $AsyncNotifierProvider<AuthController, void> {
  /// Pilote les actions d’authentification depuis l’UI. `state` reflète
  /// l’action en cours (chargement / erreur), tandis que la session réelle,
  /// elle, provient de `authSessionProvider`.
  AuthControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authControllerHash();

  @$internal
  @override
  AuthController create() => AuthController();
}

String _$authControllerHash() => r'bee6e849dce24eb57ab5b9aa1daea2f414d25e4a';

/// Pilote les actions d’authentification depuis l’UI. `state` reflète
/// l’action en cours (chargement / erreur), tandis que la session réelle,
/// elle, provient de `authSessionProvider`.

abstract class _$AuthController extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
