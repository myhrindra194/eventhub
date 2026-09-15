import 'package:eventhub/core/result/result.dart';

/// `favorites (user_id, event_id)` — the pair is the primary key, so a
/// duplicate is structurally impossible and "is it a favourite?" is a set
/// lookup on the ids already streamed. Deleting an event deletes its
/// favorites with it (foreign-key cascade).
abstract interface class FavoritesRepository {
  /// Event ids, most recently starred first.
  Stream<List<String>> watchFavoriteIds(String userId);

  /// Idempotent: starring an event already starred succeeds.
  AsyncResult<void> add({required String userId, required String eventId});

  AsyncResult<void> remove({required String userId, required String eventId});
}
