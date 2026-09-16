import 'dart:async';

import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/errors/failure_exception.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Seul endroit où les exceptions des SDK deviennent des [Failure] du
/// domaine.
///
/// Firestore dit *qu’une* écriture a été refusée, jamais *pourquoi* : les
/// règles renvoient un `permission-denied` nu. C’est pour cela que chaque
/// repository vérifie d’abord les policies du domaine (`ReservationPolicy`,
/// `EventPolicy`…) et transforme leur phrase précise en failure avant
/// d’écrire ; un refus qui parvient malgré tout jusqu’à ce mapper est une
/// course perdue (la dernière place vient de partir) ou un client trafiqué,
/// et reçoit un message générique mais honnête.
abstract final class ErrorMapper {
  static Failure fromAny(Object error, StackTrace stackTrace) {
    return switch (error) {
      FailureException(:final failure) => failure,
      FirebaseAuthException() => fromAuth(error, stackTrace),
      FirebaseException() => fromFirebase(error, stackTrace),
      TimeoutException() => NetworkFailure(
        cause: error,
        stackTrace: stackTrace,
      ),
      _ => UnexpectedFailure(cause: error, stackTrace: stackTrace),
    };
  }

  /// Codes d’erreur de Firestore (et des autres services Firebase), voir
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
      // Une transaction a perdu la course trop de fois (la dernière place,
      // un compteur).
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
      'unavailable' ||
      'deadline-exceeded' ||
      'network-request-failed' => NetworkFailure(cause: e, stackTrace: st),
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
      'invalid-email' ||
      'missing-email' => (AuthFailureCode.invalidEmail, 'Email invalide.'),
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
