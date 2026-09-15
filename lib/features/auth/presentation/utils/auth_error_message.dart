import '../../domain/failures/auth_failure.dart';

String authErrorMessage(Object? error) {
  if (error is AuthFailure) return error.message;
  return 'An authentication error occurred. Please try again.';
}
