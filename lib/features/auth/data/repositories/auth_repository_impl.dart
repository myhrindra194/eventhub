import '../../domain/entities/user.dart';
import '../../domain/failures/auth_failure.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../mappers/auth_failure_mapper.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _dataSource;

  AuthRepositoryImpl({AuthRemoteDataSource? dataSource})
    : _dataSource = dataSource ?? AuthRemoteDataSource();

  @override
  Future<User> register({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    try {
      final user = await _dataSource.register(
        email: email,
        password: password,
        name: name,
        role: role,
      );
      return user.toEntity();
    } catch (error) {
      throw _mapFailure(error);
    }
  }

  @override
  Future<User> login({required String email, required String password}) async {
    try {
      final user = await _dataSource.login(email: email, password: password);
      return user.toEntity();
    } catch (error) {
      throw _mapFailure(error);
    }
  }

  @override
  Future<User?> loginWithGoogle() async {
    try {
      final user = await _dataSource.loginWithGoogle();
      return user?.toEntity();
    } catch (error) {
      throw _mapFailure(error);
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _dataSource.sendPasswordResetEmail(email);
    } catch (error) {
      throw _mapFailure(error);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _dataSource.logout();
    } catch (error) {
      throw _mapFailure(error);
    }
  }

  @override
  Stream<User?> authStateChanges() async* {
    try {
      await for (final user in _dataSource.authStateChanges()) {
        yield user?.toEntity();
      }
    } catch (error) {
      throw _mapFailure(error);
    }
  }

  AuthFailure _mapFailure(Object error) {
    if (error is AuthFailure) return error;
    return mapAuthException(error);
  }
}
