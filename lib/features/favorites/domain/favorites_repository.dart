import 'package:eventhub/core/result/result.dart';

/// `users/{uid}/favorites/{eventId}` — indexé par l’événement : un doublon
/// est donc structurellement impossible, et « est-ce un favori ? » se
/// résout par une recherche dans l’ensemble des ids déjà diffusés. Sans
/// serveur, rien ne cascade à la suppression d’un événement : un favori qui
/// pointe vers un événement absent n’est simplement pas affiché.
abstract interface class FavoritesRepository {
  /// Identifiants d’événements, du favori le plus récent au plus ancien.
  Stream<List<String>> watchFavoriteIds(String userId);

  /// Idempotent : mettre en favori un événement qui l’est déjà réussit.
  AsyncResult<void> add({required String userId, required String eventId});

  AsyncResult<void> remove({required String userId, required String eventId});
}
