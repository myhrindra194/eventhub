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

  Future<Result<AppUser>> signIn({
    required String email,
    required String password,
  }) {
    return _run(
      () => ref
          .read(authRepositoryProvider)
          .signIn(email: email, password: password),
    );
  }

  Future<Result<AppUser>> signUp({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) {
    return _run(
      () => ref
          .read(authRepositoryProvider)
          .signUp(name: name, email: email, password: password, role: role),
    );
  }

  Future<Result<AppUser>> completeProfile({
    required String name,
    required UserRole role,
  }) {
    return _run(
      () => ref
          .read(authRepositoryProvider)
          .completeProfile(name: name, role: role),
    );
  }

  Future<Result<void>> sendPasswordReset(String email) => _run(
    () => ref.read(authRepositoryProvider).sendPasswordReset(email: email),
  );

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
