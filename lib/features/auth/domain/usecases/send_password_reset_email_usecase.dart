import '../repositories/auth_repository.dart';

class SendPasswordResetEmailUseCase {
  final AuthRepository _repository;

  const SendPasswordResetEmailUseCase(this._repository);

  Future<void> call(String email) {
    return _repository.sendPasswordResetEmail(email);
  }
}
