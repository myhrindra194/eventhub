import 'package:eventhub/core/analytics/app_analytics.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/auth/application/auth_providers.dart';
import 'package:eventhub/features/auth/domain/entities/app_user.dart';
import 'package:eventhub/features/auth/domain/entities/user_role.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' hide AsyncResult;

part 'auth_controller.g.dart';

/// Pilote les actions d’authentification depuis l’UI. `state` reflète
/// l’action en cours (chargement / erreur), tandis que la session réelle,
/// elle, provient de `authSessionProvider`.
@riverpod
class AuthController extends _$AuthController {
  @override
  FutureOr<void> build() {}

  AppAnalytics get _analytics => ref.read(appAnalyticsProvider);

  Future<Result<AppUser>> signIn({
    required String email,
    required String password,
  }) async {
    final result = await _run(
      () => ref
          .read(authRepositoryProvider)
          .signIn(email: email, password: password),
    );
    if (result is Ok<AppUser>) _analytics.login('password');
    return result;
  }

  Future<Result<void>> signInWithGoogle({
    UserRole intendedRole = UserRole.participant,
  }) async {
    final result = await _run(
      () => ref
          .read(authRepositoryProvider)
          .signInWithGoogle(intendedRole: intendedRole),
    );
    if (result is Ok<void>) _analytics.login('google');
    return result;
  }

  Future<Result<AppUser>> signUp({
    required String name,
    required String email,
    required String password,
    required UserRole intendedRole,
  }) async {
    final result = await _run(
      () => ref
          .read(authRepositoryProvider)
          .signUp(
            name: name,
            email: email,
            password: password,
            intendedRole: intendedRole,
          ),
    );
    if (result is Ok<AppUser>) _analytics.signUp('password');
    return result;
  }

  /// C’est aussi la fin d’une première connexion Google, d’où sa propre
  /// méthode d’inscription.
  Future<Result<AppUser>> completeProfile({required String name}) async {
    final result = await _run(
      () => ref.read(authRepositoryProvider).completeProfile(name: name),
    );
    if (result is Ok<AppUser>) _analytics.signUp('profile_completion');
    return result;
  }

  Future<Result<AppUser>> updateProfile({
    required String name,
    String? bio,
    String? photoUrl,
    String? coverUrl,
    bool updatePhotos = false,
  }) => _run(
    () => ref
        .read(authRepositoryProvider)
        .updateProfile(
          name: name,
          bio: bio,
          photoUrl: photoUrl,
          coverUrl: coverUrl,
          updatePhotos: updatePhotos,
        ),
  );

  Future<Result<void>> sendPasswordReset(String email) => _run(
    () => ref.read(authRepositoryProvider).sendPasswordReset(email: email),
  );

  /// Ne passe pas par `_run` : le bandeau a son propre état d’occupation, et
  /// un renvoi ne doit pas désactiver des boutons d’authentification qui
  /// n’ont rien à voir.
  Future<Result<void>> sendEmailVerification() =>
      ref.read(authRepositoryProvider).sendEmailVerification();

  Future<Result<bool>> refreshEmailVerification() =>
      ref.read(authRepositoryProvider).refreshEmailVerification();

  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) => _run(
    () => ref
        .read(authRepositoryProvider)
        .changePassword(
          currentPassword: currentPassword,
          newPassword: newPassword,
        ),
  );

  /// Après un lien de récupération de mot de passe : aucun mot de passe
  /// actuel à demander.
  Future<Result<void>> setNewPassword(String newPassword) =>
      _run(() => ref.read(authRepositoryProvider).setNewPassword(newPassword));

  Future<Result<void>> deleteAccount({String? password}) => _run(
    () => ref.read(authRepositoryProvider).deleteAccount(password: password),
  );

  Future<Result<void>> signOut() =>
      _run(() => ref.read(authRepositoryProvider).signOut());

  Future<Result<T>> _run<T>(AsyncResult<T> Function() action) async {
    state = const AsyncLoading();
    final result = await action();
    state = switch (result) {
      Ok() => const AsyncData(null),
      Err(:final failure) => AsyncError(
        failure,
        failure.stackTrace ?? StackTrace.current,
      ),
    };
    return result;
  }
}
