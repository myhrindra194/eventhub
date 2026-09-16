import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:eventhub/core/utils/app_logger.dart';
import 'package:http/http.dart' as http;

/// Demande l'envoi push d'une notification déjà écrite dans Firestore.
///
/// **Pourquoi l'app appelle un serveur.** Envoyer par FCM exige la clé du
/// compte de service Firebase, qui ne peut pas vivre dans un binaire. Sur le
/// plan Spark il n'y a pas de Cloud Functions pour réagir à l'écriture : c'est
/// donc l'auteur de la notification qui prévient le Worker Cloudflare
/// `eventhub-api` (voir `workers/api/`), juste après l'avoir écrite.
///
/// **Pourquoi c'est sûr.** Le Worker ne relaie que des notifications qui
/// existent, écrites par l'appelant (`actorId`), récentes, et une seule fois.
/// Les règles Firestore restent donc le seul juge de ce qui mérite d'être
/// notifié ; le Worker n'en est que le porte-voix.
///
/// **Toujours « au mieux ».** L'action principale (une réservation, une
/// invitation) est déjà validée quand l'envoi part : un push perdu ne doit
/// jamais la faire échouer. Les méthodes ne lèvent donc jamais et ne se font
/// pas attendre.
abstract interface class PushDispatcher {
  void notify({required String recipientId, required String notificationId});
}

/// Aucun envoi : build sans Worker configuré, et tests.
class NoPushDispatcher implements PushDispatcher {
  const NoPushDispatcher();

  @override
  void notify({required String recipientId, required String notificationId}) {}
}

/// Appelle `POST /v1/dispatch` du Worker, authentifié par l'ID token Firebase
/// de l'utilisateur connecté.
class WorkerPushDispatcher implements PushDispatcher {
  WorkerPushDispatcher({
    required http.Client client,
    required Uri endpoint,
    required Future<String?> Function() idToken,
    this.maxConcurrent = 4,
    this.timeout = const Duration(seconds: 15),
  }) : _client = client,
       _endpoint = endpoint,
       _idToken = idToken;

  final http.Client _client;
  final Uri _endpoint;
  final Future<String?> Function() _idToken;

  /// Une décision de modération peut prévenir 200 détenteurs de billets d'un
  /// coup. Quatre appels simultanés au plus : assez pour que tout parte en
  /// quelques secondes, pas assez pour saturer une connexion mobile ni le
  /// plafond de requêtes du plan gratuit Cloudflare.
  final int maxConcurrent;
  final Duration timeout;

  final _queue = Queue<({String recipientId, String notificationId})>();
  int _running = 0;
  final _idle = <Completer<void>>[];

  @override
  void notify({required String recipientId, required String notificationId}) {
    _queue.add((recipientId: recipientId, notificationId: notificationId));
    _pump();
  }

  /// Se termine quand la file est vide. Réservé aux tests : en production,
  /// personne n'attend un push.
  Future<void> drain() {
    if (_running == 0 && _queue.isEmpty) return Future.value();
    final completer = Completer<void>();
    _idle.add(completer);
    return completer.future;
  }

  void _pump() {
    while (_running < maxConcurrent && _queue.isNotEmpty) {
      final job = _queue.removeFirst();
      _running++;
      unawaited(
        _send(job.recipientId, job.notificationId).whenComplete(() {
          _running--;
          _pump();
          if (_running == 0 && _queue.isEmpty) {
            for (final completer in _idle) {
              completer.complete();
            }
            _idle.clear();
          }
        }),
      );
    }
  }

  Future<void> _send(String recipientId, String notificationId) async {
    try {
      final token = await _idToken();
      if (token == null) return;
      final response = await _client
          .post(
            _endpoint,
            headers: {
              'authorization': 'Bearer $token',
              'content-type': 'application/json',
            },
            body: jsonEncode({
              'recipientId': recipientId,
              'notificationId': notificationId,
            }),
          )
          .timeout(timeout);
      // 200 couvre aussi « déjà envoyée », « coupée par les préférences » et
      // « aucun appareil » : ce sont des issues normales, pas des erreurs.
      if (response.statusCode != 200) {
        AppLogger.warning(
          'Push dispatch refused (${response.statusCode}) for $notificationId',
        );
      }
    } on Object catch (error) {
      AppLogger.warning(
        'Push dispatch skipped for $notificationId',
        error: error,
      );
    }
  }
}
