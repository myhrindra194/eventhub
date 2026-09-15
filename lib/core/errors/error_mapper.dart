import 'dart:async';

import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/errors/failure_exception.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Single place where SDK exceptions become domain [Failure]s.
///
/// Firestore says *that* a write was refused, never *why*: the rules return
/// a bare `permission-denied`. That is why every repository checks the
/// domain policies first (`ReservationPolicy`, `EventPolicy`…) and turns
/// their precise sentence into a failure before writing; a refusal that still
/// reaches this mapper is a race (the last seat just went) or a tampered
/// client, and gets a generic but honest message.
abstract final class ErrorMapper {
  static Failure fromAny(Object error, StackTrace stackTrace) {
    return switch (error) {
      FailureException(:final failure) => failure,
      FirebaseAuthException() => fromAuth(error, stackTrace),
      FirebaseException() => fromFirebase(error, stackTrace),
      TimeoutException() => NetworkFailure(cause: error, stackTrace: stackTrace),
      _ => UnexpectedFailure(cause: error, stackTrace: stackTrace),
    };
  }

  /// Firestore (and other Firebase services) error codes, see
  /// https://firebase.google.com/docs/reference/node/firebase.firestore#firestoreerrorcode
  static Failure fromFirebase(FirebaseException e, StackTrace st) {
    return switch (e.code) {
      'permission-denied' => PermissionFailure(
        message:
            'Action refusée : vos droits ou les données ont changé. '
            'Actualisez puis réessayez.',
        cause: e,
        stackTrace: st,
      ),
      'unauthenticated' => AuthFailure(
        code: AuthFailureCode.notSignedIn,
        message: 'Vous devez être connecté.',
        cause: e,
        stackTrace: st,
      ),
      'not-found' => NotFoundFailure(
        resource: 'document',
        message: 'Ressource introuvable.',
        cause: e,
        stackTrace: st,
      ),
      'already-exists' => BusinessRuleFailure(
        rule: BusinessRule.actionRefused,
        message: 'Cette opération a déjà été faite.',
        cause: e,
        stackTrace: st,
      ),
      // A transaction lost a race too many times (the last seat, a counter).
      'aborted' => BusinessRuleFailure(
        rule: BusinessRule.actionRefused,
        message: 'Beaucoup de demandes en même temps. Réessayez.',
        cause: e,
        stackTrace: st,
      ),
      'invalid-argument' || 'out-of-range' => ValidationFailure(
        message: 'Données invalides.',
        cause: e,
        stackTrace: st,
      ),
      'unavailable' || 'deadline-exceeded' || 'network-request-failed' =>
        NetworkFailure(cause: e, stackTrace: st),
      'resource-exhausted' => NetworkFailure(
        message: 'Service saturé pour le moment. Réessayez plus tard.',
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

  static Failure fromAuth(FirebaseAuthException e, StackTrace st) {
    if (e.code == 'network-request-failed') {
      return NetworkFailure(cause: e, stackTrace: st);
    }
    final (code, message) = switch (e.code) {
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' ||
      'invalid-login-credentials' => (
        AuthFailureCode.invalidCredentials,
        'Email ou mot de passe incorrect.',
      ),
      'email-already-in-use' => (
        AuthFailureCode.emailAlreadyInUse,
        'Un compte existe déjà avec cet email.',
      ),
      'weak-password' || 'password-does-not-meet-requirements' => (
        AuthFailureCode.weakPassword,
        'Mot de passe trop faible : 8 caractères minimum, lettres et chiffres.',
      ),
      'invalid-email' || 'missing-email' => (
        AuthFailureCode.invalidEmail,
        'Email invalide.',
      ),
      'user-disabled' => (
        AuthFailureCode.userDisabled,
        'Ce compte est désactivé.',
      ),
      'too-many-requests' || 'quota-exceeded' => (
        AuthFailureCode.tooManyRequests,
        'Trop de tentatives. Réessayez dans quelques minutes.',
      ),
      'requires-recent-login' || 'user-token-expired' => (
        AuthFailureCode.requiresRecentLogin,
        'Pour des raisons de sécurité, reconnectez-vous puis réessayez.',
      ),
      'account-exists-with-different-credential' ||
      'credential-already-in-use' => (
        AuthFailureCode.accountExistsWithDifferentCredential,
        'Un compte existe déjà avec cet email. Connectez-vous avec votre mot '
            'de passe.',
      ),
      'popup-closed-by-user' ||
      'cancelled-popup-request' ||
      'web-context-canceled' => (
        AuthFailureCode.cancelled,
        'Connexion annulée.',
      ),
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
}
