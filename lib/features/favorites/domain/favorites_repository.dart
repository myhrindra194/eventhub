import 'package:eventhub/core/result/result.dart';

/// `users/{uid}/favorites/{eventId}` — keyed by the event, so a duplicate is
/// structurally impossible and "is it a favourite?" is a set lookup on the
/// ids already streamed. Without a server nothing cascades when an event is
/// deleted: a favorite pointing at a missing event is simply not shown.
abstract interface class FavoritesRepository {
  /// Event ids, most recently starred first.
  Stream<List<String>> watchFavoriteIds(String userId);

  /// Idempotent: starring an event already starred succeeds.
  AsyncResult<void> add({required String userId, required String eventId});

  AsyncResult<void> remove({required String userId, required String eventId});
}
