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

String _$authRepositoryHash() => r'269c7668db16ad47e68492f5e42b19c8ce70784a';

/// Source de vérité unique pour « qui est connecté ». Maintenue en vie
/// pendant toute la durée de vie de l’application : le router et chacune des
/// features en dérivent.

@ProviderFor(authSession)
final authSessionProvider = AuthSessionProvider._();

/// Source de vérité unique pour « qui est connecté ». Maintenue en vie
/// pendant toute la durée de vie de l’application : le router et chacune des
/// features en dérivent.

final class AuthSessionProvider
    extends
        $FunctionalProvider<
          AsyncValue<AuthSession>,
          AuthSession,
          Stream<AuthSession>
        >
    with $FutureModifier<AuthSession>, $StreamProvider<AuthSession> {
  /// Source de vérité unique pour « qui est connecté ». Maintenue en vie
  /// pendant toute la durée de vie de l’application : le router et chacune des
  /// features en dérivent.
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

/// Se déclenche lorsqu’un lien de récupération de mot de passe ouvre
/// l’application.

@ProviderFor(passwordRecovery)
final passwordRecoveryProvider = PasswordRecoveryProvider._();

/// Se déclenche lorsqu’un lien de récupération de mot de passe ouvre
/// l’application.

final class PasswordRecoveryProvider
    extends $FunctionalProvider<AsyncValue<void>, void, Stream<void>>
    with $FutureModifier<void>, $StreamProvider<void> {
  /// Se déclenche lorsqu’un lien de récupération de mot de passe ouvre
  /// l’application.
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

/// Vue de confort : l’utilisateur connecté, ou `null`.

@ProviderFor(currentUser)
final currentUserProvider = CurrentUserProvider._();

/// Vue de confort : l’utilisateur connecté, ou `null`.

final class CurrentUserProvider
    extends $FunctionalProvider<AppUser?, AppUser?, AppUser?>
    with $Provider<AppUser?> {
  /// Vue de confort : l’utilisateur connecté, ou `null`.
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
