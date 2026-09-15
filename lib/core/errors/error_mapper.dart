import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/errors/failure_exception.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Single place where SDK exceptions become domain [Failure]s.
///
/// The backend speaks one error language (see supabase/migrations, 1/8):
/// SQLSTATE `PTnnn` carries the HTTP status, `hint` the business rule — a
/// [BusinessRule] name, or `validation`, `notFound`, `notSignedIn`,
/// `accountSuspended` — `message` a French sentence safe to show, `details`
/// the field errors. Database functions return it through PostgREST, Edge
/// Functions in their JSON body: both land in [fromApiError].
abstract final class ErrorMapper {
  static Failure fromAny(Object error, StackTrace stackTrace) {
    return switch (error) {
      FailureException(:final failure) => failure,
      AuthRetryableFetchException() => NetworkFailure(
        cause: error,
        stackTrace: stackTrace,
      ),
      AuthException() => fromAuth(error, stackTrace),
      PostgrestException() => fromPostgrest(error, stackTrace),
      FunctionException() => fromFunction(error, stackTrace),
      StorageException() => StorageFailure(
        cause: error,
        stackTrace: stackTrace,
      ),
      SocketException() || TimeoutException() => NetworkFailure(
        cause: error,
        stackTrace: stackTrace,
      ),
      _ => UnexpectedFailure(cause: error, stackTrace: stackTrace),
    };
  }

  static Failure fromPostgrest(PostgrestException e, StackTrace st) =>
      fromApiError(
        code: e.code,
        message: e.message,
        hint: e.hint,
        details: e.details,
        cause: e,
        stackTrace: st,
      );

  static Failure fromFunction(FunctionException e, StackTrace st) {
    final body = e.details;
    if (body is Map) {
      return fromApiError(
        code: body['code']?.toString() ?? 'PT${e.status}',
        message: body['message']?.toString(),
        hint: body['hint']?.toString(),
        details: body['details'],
        cause: e,
        stackTrace: st,
      );
    }
    return fromApiError(code: 'PT${e.status}', cause: e, stackTrace: st);
  }

  static final _customStatus = RegExp(r'^PT(\d{3})$');

  static Failure fromApiError({
    required String? code,
    String? message,
    String? hint,
    Object? details,
    required Object cause,
    required StackTrace stackTrace,
  }) {
    final text = (message == null || message.isEmpty) ? null : message;
    final status = switch (_customStatus.firstMatch(code ?? '')) {
      final match? => int.parse(match.group(1)!),
      null => null,
    };

    if (status != null) {
      final rule = BusinessRule.values.asNameMap()[hint];
      return switch ((status, hint)) {
        (_, 'validation') || (422, _) => ValidationFailure(
          message: text ?? 'Certains champs sont invalides.',
          fieldErrors: _fieldErrors(details),
          cause: cause,
          stackTrace: stackTrace,
        ),
        (401, _) || (_, 'notSignedIn') => AuthFailure(
          code: AuthFailureCode.notSignedIn,
          message: text ?? 'Vous devez être connecté.',
          cause: cause,
          stackTrace: stackTrace,
        ),
        (_, 'accountSuspended') => AuthFailure(
          code: AuthFailureCode.userDisabled,
          message: text ?? 'Ce compte est suspendu par la modération.',
          cause: cause,
          stackTrace: stackTrace,
        ),
        _ when rule != null => BusinessRuleFailure(
          rule: rule,
          message: text ?? 'Action impossible pour le moment.',
          cause: cause,
          stackTrace: stackTrace,
        ),
        (404, _) || (_, 'notFound') => NotFoundFailure(
          resource: 'server',
          message: text ?? 'Ressource introuvable.',
          cause: cause,
          stackTrace: stackTrace,
        ),
        (403, _) => PermissionFailure(
          message: text ?? "Vous n'avez pas les droits pour cette action.",
          cause: cause,
          stackTrace: stackTrace,
        ),
        (409 || 429, _) => BusinessRuleFailure(
          rule: BusinessRule.actionRefused,
          message: text ?? 'Action impossible pour le moment.',
          cause: cause,
          stackTrace: stackTrace,
        ),
        (502 || 503 || 504, _) => NetworkFailure(
          message: text ?? 'Service momentanément indisponible. Réessayez.',
          cause: cause,
          stackTrace: stackTrace,
        ),
        _ => UnexpectedFailure(
          message: text ?? 'Une erreur inattendue est survenue.',
          cause: cause,
          stackTrace: stackTrace,
        ),
      };
    }

    return switch (code) {
      '42501' => PermissionFailure(cause: cause, stackTrace: stackTrace),
      '23505' => BusinessRuleFailure(
        rule: BusinessRule.actionRefused,
        message: 'Cette opération a déjà été faite.',
        cause: cause,
        stackTrace: stackTrace,
      ),
      '23514' || '23502' || '22P02' => ValidationFailure(
        message: 'Données invalides.',
        cause: cause,
        stackTrace: stackTrace,
      ),
      'PGRST116' => NotFoundFailure(
        resource: 'row',
        message: 'Ressource introuvable.',
        cause: cause,
        stackTrace: stackTrace,
      ),
      _ => UnexpectedFailure(
        message: 'Erreur serveur (${code ?? 'inconnue'}).',
        cause: cause,
        stackTrace: stackTrace,
      ),
    };
  }

  /// `details` is a JSON string from PostgREST, a map from an Edge Function.
  static Map<String, String> _fieldErrors(Object? details) {
    Object? decoded = details;
    if (details is String && details.trim().startsWith('{')) {
      try {
        decoded = jsonDecode(details);
      } on FormatException {
        decoded = null;
      }
    }
    if (decoded is! Map) return const {};
    return {
      for (final entry in decoded.entries)
        if (entry.value != null) '${entry.key}': '${entry.value}',
    };
  }

  static Failure fromAuth(AuthException e, StackTrace st) {
    final (code, message) = switch (e.code) {
      'invalid_credentials' => (
        AuthFailureCode.invalidCredentials,
        'Email ou mot de passe incorrect.',
      ),
      'email_exists' || 'user_already_exists' => (
        AuthFailureCode.emailAlreadyInUse,
        'Un compte existe déjà avec cet email.',
      ),
      'weak_password' => (
        AuthFailureCode.weakPassword,
        'Mot de passe trop faible : 8 caractères minimum, lettres et chiffres.',
      ),
      'same_password' => (
        AuthFailureCode.weakPassword,
        'Le nouveau mot de passe doit être différent de l’actuel.',
      ),
      'email_address_invalid' ||
      'validation_failed' => (AuthFailureCode.invalidEmail, 'Email invalide.'),
      'user_banned' => (
        AuthFailureCode.userDisabled,
        'Ce compte est suspendu par la modération.',
      ),
      'over_request_rate_limit' ||
      'over_email_send_rate_limit' ||
      'over_sms_send_rate_limit' => (
        AuthFailureCode.tooManyRequests,
        'Trop de tentatives. Réessayez dans une minute.',
      ),
      'email_not_confirmed' => (
        AuthFailureCode.unknown,
        'Confirmez votre adresse : ouvrez le lien reçu par email, puis '
            'connectez-vous.',
      ),
      'reauthentication_needed' ||
      'reauthentication_not_valid' ||
      'session_expired' ||
      'session_not_found' => (
        AuthFailureCode.requiresRecentLogin,
        'Pour des raisons de sécurité, reconnectez-vous puis réessayez.',
      ),
      'identity_already_exists' => (
        AuthFailureCode.accountExistsWithDifferentCredential,
        'Un compte existe déjà avec cet email. Connectez-vous avec votre mot '
            'de passe.',
      ),
      'provider_disabled' || 'email_provider_disabled' => (
        AuthFailureCode.unknown,
        'Ce mode de connexion n’est pas activé pour le projet.',
      ),
      _ when e.statusCode == '429' => (
        AuthFailureCode.tooManyRequests,
        'Trop de tentatives. Réessayez dans une minute.',
      ),
      _ => (
        AuthFailureCode.unknown,
        "Échec de l'authentification${e.code == null ? '' : ' (${e.code})'}.",
      ),
    };
    return AuthFailure(code: code, message: message, cause: e, stackTrace: st);
  }
}
