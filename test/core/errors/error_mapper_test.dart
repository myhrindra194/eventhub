import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' show FirebaseException;
import 'package:eventhub/core/errors/error_mapper.dart';
import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/errors/failure_exception.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import 'package:flutter_test/flutter_test.dart';

void main() {
  Failure map(Object error) => ErrorMapper.fromAny(error, StackTrace.empty);

  FirebaseException firestore(String code) =>
      FirebaseException(plugin: 'cloud_firestore', code: code);

  group('Firestore', () {
    test('a refused write is a permission failure, never a silent success', () {
      final failure = map(firestore('permission-denied'));
      expect(failure, isA<PermissionFailure>());
      // Les règles ne disent jamais *pourquoi* ; le message doit donc suggérer
      // ce que l'utilisateur peut faire, au lieu de feindre de le savoir.
      expect(failure.message, contains('Actualisez'));
    });

    test('an unauthenticated call asks to sign in', () {
      final failure = map(firestore('unauthenticated'));
      expect((failure as AuthFailure).code, AuthFailureCode.notSignedIn);
    });

    test('a missing document is a not-found failure', () {
      expect(map(firestore('not-found')), isA<NotFoundFailure>());
    });

    test('a duplicate and a lost transaction are refused actions', () {
      for (final code in ['already-exists', 'aborted']) {
        final failure = map(firestore(code));
        expect(failure, isA<BusinessRuleFailure>(), reason: code);
        expect(
          (failure as BusinessRuleFailure).rule,
          BusinessRule.actionRefused,
          reason: code,
        );
      }
    });

    test('malformed data is a validation failure', () {
      expect(map(firestore('invalid-argument')), isA<ValidationFailure>());
      expect(map(firestore('out-of-range')), isA<ValidationFailure>());
    });

    test('an unreachable or saturated backend is a network failure', () {
      expect(map(firestore('unavailable')), isA<NetworkFailure>());
      expect(map(firestore('deadline-exceeded')), isA<NetworkFailure>());
      expect(map(firestore('resource-exhausted')), isA<NetworkFailure>());
    });

    test('an unknown code keeps the code in the message', () {
      final failure = map(firestore('data-loss'));
      expect(failure, isA<UnexpectedFailure>());
      expect(failure.message, contains('data-loss'));
    });
  });

  group('Firebase Auth', () {
    AuthFailureCode codeOf(String code) =>
        (map(FirebaseAuthException(code: code)) as AuthFailure).code;

    test('maps the credential codes', () {
      expect(codeOf('invalid-credential'), AuthFailureCode.invalidCredentials);
      expect(codeOf('wrong-password'), AuthFailureCode.invalidCredentials);
      expect(codeOf('user-not-found'), AuthFailureCode.invalidCredentials);
      expect(codeOf('email-already-in-use'), AuthFailureCode.emailAlreadyInUse);
      expect(codeOf('weak-password'), AuthFailureCode.weakPassword);
      expect(codeOf('invalid-email'), AuthFailureCode.invalidEmail);
      expect(codeOf('user-disabled'), AuthFailureCode.userDisabled);
      expect(codeOf('too-many-requests'), AuthFailureCode.tooManyRequests);
      expect(
        codeOf('requires-recent-login'),
        AuthFailureCode.requiresRecentLogin,
      );
    });

    test('a closed Google popup is a cancellation, not an error', () {
      expect(codeOf('popup-closed-by-user'), AuthFailureCode.cancelled);
    });

    test('shows a French message rather than the SDK one', () {
      final failure = map(
        FirebaseAuthException(
          code: 'invalid-credential',
          message: 'The supplied auth credential is malformed.',
        ),
      );
      expect(failure.message, 'Email ou mot de passe incorrect.');
    });

    test('a network error while signing in is a network failure', () {
      expect(
        map(FirebaseAuthException(code: 'network-request-failed')),
        isA<NetworkFailure>(),
      );
    });
  });

  group('everything else', () {
    test('a timeout is a network failure', () {
      expect(map(TimeoutException('too slow')), isA<NetworkFailure>());
    });

    test('a FailureException passes its failure through', () {
      const inner = NotFoundFailure(resource: 'event', message: 'Introuvable.');
      expect(map(const FailureException(inner)), same(inner));
    });

    test('anything else is unexpected rather than swallowed', () {
      expect(map(StateError('boom')), isA<UnexpectedFailure>());
    });
  });
}
