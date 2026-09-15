// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(authRepository)
final authRepositoryProvider = AuthRepositoryProvider._();

final class AuthRepositoryProvider
    extends $FunctionalProvider<AuthRepository, AuthRepository, AuthRepository>
    with $Provider<AuthRepository> {
  AuthRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authRepositoryHash();

  @$internal
  @override
  $ProviderElement<AuthRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthRepository create(Ref ref) {
    return authRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthRepository>(value),
    );
  }
}

String _$authRepositoryHash() => r'9b1df2d80c1dbbaab2a766ca7070de8954557fa1';

/// Single source of truth for "who is logged in". Kept alive for the whole
/// app lifetime: the router and every feature derive from it.

@ProviderFor(authSession)
final authSessionProvider = AuthSessionProvider._();

/// Single source of truth for "who is logged in". Kept alive for the whole
/// app lifetime: the router and every feature derive from it.

final class AuthSessionProvider
    extends
        $FunctionalProvider<
          AsyncValue<AuthSession>,
          AuthSession,
          Stream<AuthSession>
        >
    with $FutureModifier<AuthSession>, $StreamProvider<AuthSession> {
  /// Single source of truth for "who is logged in". Kept alive for the whole
  /// app lifetime: the router and every feature derive from it.
  AuthSessionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authSessionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authSessionHash();

  @$internal
  @override
  $StreamProviderElement<AuthSession> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<AuthSession> create(Ref ref) {
    return authSession(ref);
  }
}

String _$authSessionHash() => r'f96bf54429b058c7e1d0ebf0ab587907b7ac5457';

/// Fires when a password-recovery link opens the app.

@ProviderFor(passwordRecovery)
final passwordRecoveryProvider = PasswordRecoveryProvider._();

/// Fires when a password-recovery link opens the app.

final class PasswordRecoveryProvider
    extends $FunctionalProvider<AsyncValue<void>, void, Stream<void>>
    with $FutureModifier<void>, $StreamProvider<void> {
  /// Fires when a password-recovery link opens the app.
  PasswordRecoveryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'passwordRecoveryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$passwordRecoveryHash();

  @$internal
  @override
  $StreamProviderElement<void> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<void> create(Ref ref) {
    return passwordRecovery(ref);
  }
}

String _$passwordRecoveryHash() => r'3f52133f83dc859933b0763f296ab7276aa48869';

/// Convenience view: the signed-in user or `null`.

@ProviderFor(currentUser)
final currentUserProvider = CurrentUserProvider._();

/// Convenience view: the signed-in user or `null`.

final class CurrentUserProvider
    extends $FunctionalProvider<AppUser?, AppUser?, AppUser?>
    with $Provider<AppUser?> {
  /// Convenience view: the signed-in user or `null`.
  CurrentUserProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentUserProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentUserHash();

  @$internal
  @override
  $ProviderElement<AppUser?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppUser? create(Ref ref) {
    return currentUser(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppUser? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppUser?>(value),
    );
  }
}

String _$currentUserHash() => r'e131fd05856b6d682528b0003982ecebd5116d43';
