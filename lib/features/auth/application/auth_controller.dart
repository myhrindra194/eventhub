import 'package:eventhub/core/analytics/app_analytics.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/auth/application/auth_providers.dart';
import 'package:eventhub/features/auth/domain/entities/app_user.dart';
import 'package:eventhub/features/auth/domain/entities/user_role.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' hide AsyncResult;

part 'auth_controller.g.dart';

/// Drives auth actions from the UI. `state` mirrors the in-flight action
/// (loading / error) while the actual session comes from `authSessionProvider`.
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

  Future<Result<void>> signInWithGoogle() async {
    final result = await _run(
      () => ref.read(authRepositoryProvider).signInWithGoogle(),
    );
    if (result is Ok<void>) _analytics.login('google');
    return result;
  }

  Future<Result<AppUser>> signUp({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final result = await _run(
      () => ref
          .read(authRepositoryProvider)
          .signUp(name: name, email: email, password: password, role: role),
    );
    if (result is Ok<AppUser>) _analytics.signUp('password');
    return result;
  }

  /// Also the end of a first Google sign-in, hence its own sign-up method.
  Future<Result<AppUser>> completeProfile({
    required String name,
    required UserRole role,
  }) async {
    final result = await _run(
      () => ref
          .read(authRepositoryProvider)
          .completeProfile(name: name, role: role),
    );
    if (result is Ok<AppUser>) _analytics.signUp('profile_completion');
    return result;
  }

  Future<Result<AppUser>> updateProfile({required String name}) =>
      _run(() => ref.read(authRepositoryProvider).updateProfile(name: name));

  Future<Result<void>> sendPasswordReset(String email) => _run(
    () => ref.read(authRepositoryProvider).sendPasswordReset(email: email),
  );

  /// Not routed through `_run`: the banner has its own busy state, and a
  /// resend must not disable unrelated auth buttons.
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
