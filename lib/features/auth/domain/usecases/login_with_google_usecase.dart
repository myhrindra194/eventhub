import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class LoginWithGoogleUseCase {
  final AuthRepository _repository;

  const LoginWithGoogleUseCase(this._repository);

  Future<User?> call() {
    return _repository.loginWithGoogle();
  }
}
