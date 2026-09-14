import 'dart:async';
import 'dart:io';

import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/errors/failure_exception.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Single place where platform/SDK exceptions become domain [Failure]s.
abstract final class ErrorMapper {
  static Failure fromAny(Object error, StackTrace stackTrace) {
    return switch (error) {
      FailureException(:final failure) => failure,
      FirebaseAuthException() => fromFirebaseAuth(error, stackTrace),
      FirebaseException() => fromFirebase(error, stackTrace),
      SocketException() || TimeoutException() => NetworkFailure(
        cause: error,
        stackTrace: stackTrace,
      ),
      _ => UnexpectedFailure(cause: error, stackTrace: stackTrace),
    };
  }

  static Failure fromFirebaseAuth(FirebaseAuthException e, StackTrace st) {
    final (code, message) = switch (e.code) {
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' ||
      'INVALID_LOGIN_CREDENTIALS' => (
        AuthFailureCode.invalidCredentials,
        'Email ou mot de passe incorrect.',
      ),
      'email-already-in-use' => (
        AuthFailureCode.emailAlreadyInUse,
        'Un compte existe déjà avec cet email.',
      ),
      'weak-password' => (
        AuthFailureCode.weakPassword,
        'Mot de passe trop faible (6 caractères minimum).',
      ),
      'invalid-email' => (AuthFailureCode.invalidEmail, 'Email invalide.'),
      'user-disabled' => (AuthFailureCode.userDisabled, 'Compte désactivé.'),
      'too-many-requests' => (
        AuthFailureCode.tooManyRequests,
        'Trop de tentatives. Réessayez plus tard.',
      ),
      'network-request-failed' => (
        AuthFailureCode.unknown,
        'Connexion impossible. Vérifiez votre réseau.',
      ),
      'account-exists-with-different-credential' ||
      'credential-already-in-use' => (
        AuthFailureCode.accountExistsWithDifferentCredential,
        'Un compte existe déjà avec cet email. Connectez-vous avec votre mot '
            'de passe.',
      ),
      'requires-recent-login' => (
        AuthFailureCode.requiresRecentLogin,
        'Pour des raisons de sécurité, reconnectez-vous puis réessayez.',
      ),
      'popup-closed-by-user' ||
      'cancelled-popup-request' ||
      'web-context-canceled' ||
      'sign-in-cancelled' => (AuthFailureCode.cancelled, 'Connexion annulée.'),
      'operation-not-allowed' => (
        AuthFailureCode.unknown,
        'Ce mode de connexion n’est pas activé pour le projet.',
      ),
      _ => (
        AuthFailureCode.unknown,
        "Échec de l'authentification (${e.code}).",
      ),
    };
    return AuthFailure(code: code, message: message, cause: e, stackTrace: st);
  }

  static Failure fromFirebase(FirebaseException e, StackTrace st) {
    // Callable Cloud Functions carry a user-facing French message written on
    // the server (HttpsError); show it rather than a generic one.
    if (e.plugin == 'firebase_functions') {
      final serverMessage = e.message;
      return switch (e.code) {
        'unauthenticated' => AuthFailure(
          code: AuthFailureCode.notSignedIn,
          message: serverMessage ?? 'Vous devez être connecté.',
          cause: e,
          stackTrace: st,
        ),
        'failed-precondition' => BusinessRuleFailure(
          rule: BusinessRule.accountDeletionBlocked,
          message: serverMessage ?? 'Action impossible pour le moment.',
          cause: e,
          stackTrace: st,
        ),
        'unavailable' ||
        'deadline-exceeded' => NetworkFailure(cause: e, stackTrace: st),
        _ => UnexpectedFailure(
          message: serverMessage ?? 'Erreur serveur (${e.code}).',
          cause: e,
          stackTrace: st,
        ),
      };
    }
    return switch (e.code) {
      'permission-denied' => PermissionFailure(cause: e, stackTrace: st),
      'unavailable' ||
      'deadline-exceeded' ||
      'network-request-failed' => NetworkFailure(cause: e, stackTrace: st),
      'not-found' || 'object-not-found' => NotFoundFailure(
        resource: e.plugin,
        message: 'Ressource introuvable.',
        cause: e,
        stackTrace: st,
      ),
      _ when e.plugin == 'firebase_storage' => StorageFailure(
        cause: e,
        stackTrace: st,
      ),
      _ => UnexpectedFailure(
        message: 'Erreur serveur (${e.code}).',
        cause: e,
        stackTrace: st,
      ),
    };
  }
}
