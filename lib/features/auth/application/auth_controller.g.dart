// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Drives auth actions from the UI. `state` mirrors the in-flight action
/// (loading / error) while the actual session comes from `authSessionProvider`.

@ProviderFor(AuthController)
final authControllerProvider = AuthControllerProvider._();

/// Drives auth actions from the UI. `state` mirrors the in-flight action
/// (loading / error) while the actual session comes from `authSessionProvider`.
final class AuthControllerProvider
    extends $AsyncNotifierProvider<AuthController, void> {
  /// Drives auth actions from the UI. `state` mirrors the in-flight action
  /// (loading / error) while the actual session comes from `authSessionProvider`.
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

String _$authControllerHash() => r'913f84007af2e37b7ab0f3d2fd735442b2ab1f7e';

/// Drives auth actions from the UI. `state` mirrors the in-flight action
/// (loading / error) while the actual session comes from `authSessionProvider`.

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
