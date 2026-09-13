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
      case 'network-request-failed':
        return UnknownAuthFailure(
          'No internet connection. Please check your network and try again.',
        );
      case 'user-disabled':
        return UnknownAuthFailure(
          'This account has been disabled. Please contact support.',
        );
      case 'operation-not-allowed':
        return UnknownAuthFailure(
          'This sign-in method is not enabled. Please contact support.',
        );
      case 'user-creation-failed':
        return UnknownAuthFailure(
          error.message ?? 'Unable to retrieve the signed-in user.',
        );
      default:
        return UnknownAuthFailure(
          error.message ?? 'Firebase Auth error: ${error.code}',
        );
    }
  }

  if (error is FirebaseException) {
    return UnknownAuthFailure(error.message ?? 'Firebase error: ${error.code}');
  }

  return UnknownAuthFailure(error.toString());
}
