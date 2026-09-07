import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl();
});

final authProvider = NotifierProvider<AuthNotifier, AsyncValue<User?>>(
  AuthNotifier.new,
);

class AuthNotifier extends Notifier<AsyncValue<User?>> {
  late final AuthRepository _repository;

  @override
  AsyncValue<User?> build() {
    _repository = ref.watch(authRepositoryProvider);
    return const AsyncValue.data(null);
  }

  Future<void> register({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    state = const AsyncValue.loading();

    try {
      final credential = await _repository.register(
        email: email,
        password: password,
        name: name,
        role: role,
      );

      state = AsyncValue.data(credential.user);
    } on FirebaseAuthException catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncValue.loading();

    try {
      final credential = await _repository.login(
        email: email,
        password: password,
      );

      state = AsyncValue.data(credential.user);
    } on FirebaseAuthException catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();

    try {
      await _repository.logout();
      state = const AsyncValue.data(null);
    } on FirebaseAuthException catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  User? get currentUser => _repository.getCurrentUser();
}
