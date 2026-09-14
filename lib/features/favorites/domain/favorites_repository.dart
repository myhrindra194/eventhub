import 'package:eventhub/core/result/result.dart';

/// `users/{uid}/favorites/{eventId}` — document id equals the event id, so a
/// duplicate is structurally impossible and "is it a favourite?" is a set
/// lookup on the ids already streamed.
abstract interface class FavoritesRepository {
  /// Event ids, most recently starred first.
  Stream<List<String>> watchFavoriteIds(String userId);

  AsyncResult<void> add({required String userId, required String eventId});

  AsyncResult<void> remove({required String userId, required String eventId});
}
