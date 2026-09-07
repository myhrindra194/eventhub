import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthRepository {
  Future<UserCredential> register({
    required String email,
    required String password,
    required String name,
    required String role,
  });

  Future<UserCredential> login({
    required String email,
    required String password,
  });

  Future<void> logout();

  User? getCurrentUser();
}
