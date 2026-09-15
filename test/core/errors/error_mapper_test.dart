import 'dart:io';

import 'package:eventhub/core/errors/error_mapper.dart';
import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/errors/failure_exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  Failure map(Object error) => ErrorMapper.fromAny(error, StackTrace.empty);

  group('database functions (PostgREST)', () {
    test('a business rule in the hint keeps the server message', () {
      final failure = map(
        const PostgrestException(
          code: 'PT409',
          message: 'Plus aucune place disponible.',
          hint: 'eventFull',
        ),
      );
      expect(failure, isA<BusinessRuleFailure>());
      expect((failure as BusinessRuleFailure).rule, BusinessRule.eventFull);
      expect(failure.message, 'Plus aucune place disponible.');
    });

    test('422 decodes the field errors from the details JSON string', () {
      final failure = map(
        const PostgrestException(
          code: 'PT422',
          message: 'Certains champs sont invalides.',
          hint: 'validation',
          details: '{"title":"Titre trop court.","capacity":"Au moins 1."}',
        ),
      );
      expect(failure, isA<ValidationFailure>());
      expect((failure as ValidationFailure).fieldErrors, {
        'title': 'Titre trop court.',
        'capacity': 'Au moins 1.',
      });
      expect(failure.message, 'Certains champs sont invalides.');
    });

    test('401 asks to sign in', () {
      final failure = map(
        const PostgrestException(code: 'PT401', message: 'Connectez-vous.'),
      );
      expect((failure as AuthFailure).code, AuthFailureCode.notSignedIn);
    });

    test('a suspended account is a disabled user', () {
      final failure = map(
        const PostgrestException(
          code: 'PT403',
          message: 'Ce compte est suspendu.',
          hint: 'accountSuspended',
        ),
      );
      expect((failure as AuthFailure).code, AuthFailureCode.userDisabled);
      expect(failure.message, 'Ce compte est suspendu.');
    });

    test('404 is a missing resource with the server text', () {
      final failure = map(
        const PostgrestException(
          code: 'PT404',
          message: 'Événement introuvable.',
          hint: 'notFound',
        ),
      );
      expect(failure, isA<NotFoundFailure>());
      expect(failure.message, 'Événement introuvable.');
    });

    test('403 without a known rule is a permission failure', () {
      final failure = map(
        const PostgrestException(
          code: 'PT403',
          message: 'Réservé à l’administration.',
          hint: 'somethingElse',
        ),
      );
      expect(failure, isA<PermissionFailure>());
      expect(failure.message, 'Réservé à l’administration.');
    });

    test('an RLS refusal (42501) is a permission failure', () {
      final failure = map(
        const PostgrestException(
          code: '42501',
          message: 'new row violates row-level security policy',
        ),
      );
      expect(failure, isA<PermissionFailure>());
    });

    test('a unique violation (23505) is a refused action', () {
      final failure = map(
        const PostgrestException(
          code: '23505',
          message: 'duplicate key value violates unique constraint',
        ),
      );
      expect(failure, isA<BusinessRuleFailure>());
      expect((failure as BusinessRuleFailure).rule, BusinessRule.actionRefused);
    });
  });

  group('Edge Functions', () {
    test('a JSON error body maps like PostgREST', () {
      final failure = map(
        const FunctionException(
          status: 409,
          details: {
            'code': 'PT409',
            'message': 'Paiement déjà en cours.',
            'hint': 'paymentPending',
          },
        ),
      );
      expect(failure, isA<BusinessRuleFailure>());
      expect(
        (failure as BusinessRuleFailure).rule,
        BusinessRule.paymentPending,
      );
      expect(failure.message, 'Paiement déjà en cours.');
    });

    test('field errors come as a map in the body', () {
      final failure = map(
        const FunctionException(
          status: 422,
          details: {
            'code': 'PT422',
            'message': 'Montant invalide.',
            'hint': 'validation',
            'details': {'amount': 'Au moins 1 €.'},
          },
        ),
      );
      expect((failure as ValidationFailure).fieldErrors, {
        'amount': 'Au moins 1 €.',
      });
    });

    test('a body without code falls back to the HTTP status', () {
      final failure = map(
        const FunctionException(status: 404, details: 'Not Found'),
      );
      expect(failure, isA<NotFoundFailure>());
    });
  });

  group('auth', () {
    AuthFailureCode codeOf(String code, {String? status}) =>
        (map(AuthException('refused', code: code, statusCode: status))
                as AuthFailure)
            .code;

    test('maps the Supabase Auth error codes', () {
      expect(
        codeOf('invalid_credentials', status: '400'),
        AuthFailureCode.invalidCredentials,
      );
      expect(codeOf('weak_password'), AuthFailureCode.weakPassword);
      expect(codeOf('user_banned'), AuthFailureCode.userDisabled);
      expect(
        codeOf('over_request_rate_limit', status: '429'),
        AuthFailureCode.tooManyRequests,
      );
    });

    test('shows a French message rather than the SDK one', () {
      final failure = map(
        const AuthException('Invalid login', code: 'invalid_credentials'),
      );
      expect(failure.message, 'Email ou mot de passe incorrect.');
    });
  });

  group('everything else', () {
    test('a Storage error is a storage failure', () {
      expect(
        map(const StorageException('Payload too large', statusCode: '413')),
        isA<StorageFailure>(),
      );
    });

    test('a socket error is a network failure', () {
      expect(
        map(const SocketException('Failed host lookup')),
        isA<NetworkFailure>(),
      );
    });

    test('a FailureException passes its failure through', () {
      const inner = NotFoundFailure(resource: 'event', message: 'Introuvable.');
      expect(map(const FailureException(inner)), same(inner));
    });
  });
}
