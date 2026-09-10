import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

class UnsupportedAuthRepository implements AuthRepository {
  const UnsupportedAuthRepository();

  @override
  Future<User> register({
    required String email,
    required String password,
    required String name,
    required String role,
  }) {
    return Future.error(UnsupportedError('Firebase Auth is unavailable.'));
  }

  @override
  Future<User> login({required String email, required String password}) {
    return Future.error(UnsupportedError('Firebase Auth is unavailable.'));
  }

  @override
  Future<User?> loginWithGoogle() {
    return Future.error(UnsupportedError('Firebase Auth is unavailable.'));
  }

  @override
  Future<void> sendPasswordResetEmail(String email) {
    return Future.error(UnsupportedError('Firebase Auth is unavailable.'));
  }

  @override
  Future<void> logout() {
    return Future.error(UnsupportedError('Firebase Auth is unavailable.'));
  }

  @override
  Stream<User?> authStateChanges() => Stream<User?>.value(null);
}
