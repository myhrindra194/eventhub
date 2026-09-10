import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/failures/auth_failure.dart';

AuthFailure mapAuthException(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return const InvalidCredentialsFailure();
      case 'email-already-in-use':
        return const EmailAlreadyInUseFailure();
      case 'invalid-email':
        return const InvalidEmailFailure();
      case 'weak-password':
        return const WeakPasswordFailure();
      case 'too-many-requests':
        return const TooManyRequestsFailure();
      default:
        return UnknownAuthFailure(
          error.message ?? 'Firebase Auth error: ${error.code}',
        );
    }
  }

  return UnknownAuthFailure(error.toString());
}
