import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository _repository;

  const RegisterUseCase(this._repository);

  Future<User> call({
    required String email,
    required String password,
    required String name,
    required String role,
  }) {
    return _repository.register(
      email: email,
      password: password,
      name: name,
      role: role,
    );
  }
}
