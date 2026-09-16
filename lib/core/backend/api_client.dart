import 'dart:async';
import 'dart:convert';

import 'package:eventhub/core/config/app_config.dart';
import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/firebase/firebase_providers.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/core/utils/app_logger.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart' hide AsyncResult;

part 'api_client.g.dart';

/// Client du Worker Cloudflare `eventhub-api` (`workers/api/`), le seul code
/// serveur du projet : emails transactionnels et envoi des push FCM.
///
/// Chaque appel porte l'ID token Firebase de l'utilisateur connecté ; c'est
/// lui, pas une clé embarquée dans l'app, qui autorise la requête côté
/// serveur. Les réponses d'erreur du Worker sont des codes courts
/// (`too_many_messages`, `mail_not_configured`…) : ce client les traduit en
/// [Failure] porteuses d'une phrase française, pour que les écrans n'aient
/// jamais à connaître le protocole.
class ApiClient {
  ApiClient({
    required http.Client client,
    required String baseUrl,
    required Future<String?> Function() idToken,
    this.timeout = const Duration(seconds: 20),
  }) : _client = client,
       _baseUrl = baseUrl,
       _idToken = idToken;

  final http.Client _client;
  final String _baseUrl;
  final Future<String?> Function() _idToken;
  final Duration timeout;

  /// Faux quand l'app a été construite sans `API_WORKER_URL` : les écrans
  /// désactivent alors ce qui en dépend au lieu d'échouer à l'usage.
  bool get isConfigured => _baseUrl.isNotEmpty;

  AsyncResult<Map<String, dynamic>> post(
    String path, [
    Map<String, Object?> body = const {},
  ]) async {
    if (!isConfigured) return const Err(_unavailable);
    try {
      final token = await _idToken();
      if (token == null) return const Err(AuthFailure.notSignedIn());
      final response = await _client
          .post(
            Uri.parse(_baseUrl).resolve(path),
            headers: {
              'authorization': 'Bearer $token',
              'content-type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(timeout);
      final decoded = _decode(response.body);
      if (response.statusCode == 200) return Ok(decoded);
      final code = decoded['error'] as String? ?? '';
      AppLogger.warning('API $path refused (${response.statusCode}: $code)');
      return Err(failureFor(response.statusCode, code));
    } on TimeoutException catch (error, stackTrace) {
      return Err(NetworkFailure(cause: error, stackTrace: stackTrace));
    } on http.ClientException catch (error, stackTrace) {
      return Err(NetworkFailure(cause: error, stackTrace: stackTrace));
    }
  }

  static Map<String, dynamic> _decode(String body) {
    try {
      final value = jsonDecode(body);
      return value is Map<String, dynamic> ? value : const {};
    } on FormatException {
      return const {};
    }
  }

  static const _unavailable = BusinessRuleFailure(
    rule: BusinessRule.actionRefused,
    message: 'Ce service n’est pas encore disponible sur cette version.',
  );

  /// Traduction des codes du Worker. Exposée pour les tests : c'est le seul
  /// endroit où le vocabulaire du serveur rencontre celui de l'écran.
  static Failure failureFor(int status, String code) => switch (code) {
    'too_many_messages' => const BusinessRuleFailure(
      rule: BusinessRule.actionRefused,
      message:
          'Votre message précédent vient de partir. Patientez deux minutes '
          'avant d’en envoyer un autre.',
    ),
    'mail_not_configured' => _unavailable,
    'bad_subject' => const ValidationFailure(
      message: 'L’objet doit faire entre 3 et 120 caractères.',
      fieldErrors: {'subject': 'Entre 3 et 120 caractères.'},
    ),
    'bad_message' => const ValidationFailure(
      message: 'Le message doit faire entre 10 et 5 000 caractères.',
      fieldErrors: {'message': 'Entre 10 et 5 000 caractères.'},
    ),
    _ when status == 401 => const AuthFailure(
      code: AuthFailureCode.notSignedIn,
      message: 'Votre session a expiré. Reconnectez-vous puis réessayez.',
    ),
    _ => const UnexpectedFailure(
      message: 'Le service ne répond pas pour le moment. Réessayez plus tard.',
    ),
  };
}

@Riverpod(keepAlive: true)
ApiClient apiClient(Ref ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  final auth = ref.watch(firebaseAuthProvider);
  return ApiClient(
    client: client,
    baseUrl: ref.watch(appConfigProvider).apiWorkerUrl,
    // Lu à chaque appel : le SDK renouvelle le jeton avant son expiration.
    idToken: () async => auth.currentUser?.getIdToken(),
  );
}
