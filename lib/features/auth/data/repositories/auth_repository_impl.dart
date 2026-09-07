import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _dataSource;

  AuthRepositoryImpl({AuthRemoteDataSource? dataSource})
    : _dataSource = dataSource ?? AuthRemoteDataSource();

  @override
  Future<UserCredential> register({
    required String email,
    required String password,
    required String name,
    required String role,
  }) {
    return _dataSource.register(
      email: email,
      password: password,
      name: name,
      role: role,
    );
  }

  @override
  Future<UserCredential> login({
    required String email,
    required String password,
  }) {
    return _dataSource.login(email: email, password: password);
  }

  @override
  Future<void> logout() {
    return _dataSource.logout();
  }

  @override
  User? getCurrentUser() {
    return _dataSource.getCurrentUser();
  }
}
