import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/auth_dependencies.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/login_with_google_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/send_password_reset_email_usecase.dart';

final authProvider = NotifierProvider<AuthNotifier, AsyncValue<User?>>(
  AuthNotifier.new,
);

class AuthNotifier extends Notifier<AsyncValue<User?>> {
  late final AuthRepository _repository;
  late final LoginUseCase _loginUseCase;
  late final LoginWithGoogleUseCase _loginWithGoogleUseCase;
  late final RegisterUseCase _registerUseCase;
  late final LogoutUseCase _logoutUseCase;
  late final SendPasswordResetEmailUseCase _sendPasswordResetEmailUseCase;

  @override
  AsyncValue<User?> build() {
    _repository = ref.watch(authRepositoryProvider);
    _loginUseCase = ref.watch(loginUseCaseProvider);
    _loginWithGoogleUseCase = ref.watch(loginWithGoogleUseCaseProvider);
    _registerUseCase = ref.watch(registerUseCaseProvider);
    _logoutUseCase = ref.watch(logoutUseCaseProvider);
    _sendPasswordResetEmailUseCase = ref.watch(
      sendPasswordResetEmailUseCaseProvider,
    );

    final subscription = _repository.authStateChanges().listen(
      (user) => state = AsyncValue.data(user),
      onError: (Object error, StackTrace stackTrace) {
        state = AsyncValue.error(error, stackTrace);
      },
    );

    ref.onDispose(subscription.cancel);

    return const AsyncValue.loading();
  }

  Future<void> register({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    state = const AsyncValue.loading();

    try {
      final user = await _registerUseCase(
        email: email,
        password: password,
        name: name,
        role: role,
      );
      state = AsyncValue.data(user);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncValue.loading();

    try {
      final user = await _loginUseCase(email: email, password: password);
      state = AsyncValue.data(user);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();

    try {
      await _logoutUseCase();
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<User?> loginWithGoogle() async {
    state = const AsyncValue.loading();

    try {
      final user = await _loginWithGoogleUseCase();
      state = AsyncValue.data(user);
      return user;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return null;
    }
  }

  /// Envoie l'email de réinitialisation sans jamais casser la session.
  ///
  /// L'erreur éventuelle est relayée à l'appelant (voir
  /// ForgotPasswordScreen) au lieu d'être stockée dans [state] : mettre
  /// [state] en erreur écrase l'utilisateur courant et déclenche une
  /// redirection par AuthGuard.
  Future<void> sendPasswordResetEmail(String email) async {
    final previousState = state;
    state = const AsyncValue.loading();

    try {
      await _sendPasswordResetEmailUseCase(email);
    } catch (error, stackTrace) {
      state = previousState;
      Error.throwWithStackTrace(error, stackTrace);
    }

    // Ne pas écraser la session : on restaure l'état précédent,
    // sinon l'utilisateur connecté est déconnecté visuellement.
    state = previousState;
  }
}
