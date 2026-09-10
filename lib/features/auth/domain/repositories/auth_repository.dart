import '../entities/user.dart';

abstract class AuthRepository {
  Future<User> register({
    required String email,
    required String password,
    required String name,
    required String role,
  });

  Future<User> login({required String email, required String password});

  Future<User?> loginWithGoogle();

  Future<void> sendPasswordResetEmail(String email);

  Future<void> logout();

  Stream<User?> authStateChanges();
}
