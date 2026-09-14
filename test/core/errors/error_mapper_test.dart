import 'package:eventhub/core/errors/error_mapper.dart';
import 'package:eventhub/core/errors/failure.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Failure map(Object error) => ErrorMapper.fromAny(error, StackTrace.empty);

  group('auth', () {
    test('a closed Google picker is a cancellation, not an error', () {
      final failure = map(FirebaseAuthException(code: 'sign-in-cancelled'));
      expect(failure, isA<AuthFailure>());
      expect((failure as AuthFailure).code, AuthFailureCode.cancelled);
    });

    test('an email already tied to a password account is explained', () {
      final failure = map(
        FirebaseAuthException(code: 'account-exists-with-different-credential'),
      );
      expect(
        (failure as AuthFailure).code,
        AuthFailureCode.accountExistsWithDifferentCredential,
      );
    });

    test('a stale session asks to sign in again', () {
      final failure = map(FirebaseAuthException(code: 'requires-recent-login'));
      expect(
        (failure as AuthFailure).code,
        AuthFailureCode.requiresRecentLogin,
      );
    });
  });

  group('callable functions', () {
    FirebaseException functions(String code, [String? message]) =>
        FirebaseException(
          plugin: 'firebase_functions',
          code: code,
          message: message,
        );

    test('keeps the French message written by the server', () {
      final failure = map(
        functions(
          'failed-precondition',
          'Suppression impossible : 1 événement',
        ),
      );
      expect(failure, isA<BusinessRuleFailure>());
      expect((failure as BusinessRuleFailure).rule, BusinessRule.actionRefused);
      expect(failure.message, 'Suppression impossible : 1 événement');
    });

    test(
      'maps refusals, bad requests and missing targets with the server text',
      () {
        final denied = map(
          functions('permission-denied', 'Réservé à l’administration.'),
        );
        expect(denied, isA<PermissionFailure>());
        expect(denied.message, 'Réservé à l’administration.');

        final invalid = map(
          functions('invalid-argument', 'Expliquez la décision.'),
        );
        expect(invalid, isA<ValidationFailure>());
        expect(invalid.message, 'Expliquez la décision.');

        final missing = map(
          functions('not-found', 'Aucun compte avec cet email.'),
        );
        expect(missing, isA<NotFoundFailure>());
        expect(missing.message, 'Aucun compte avec cet email.');
      },
    );

    test('maps unauthenticated to a sign-in failure', () {
      final failure = map(functions('unauthenticated'));
      expect((failure as AuthFailure).code, AuthFailureCode.notSignedIn);
    });

    test('maps unavailability to a network failure', () {
      expect(map(functions('unavailable')), isA<NetworkFailure>());
    });
  });
}
