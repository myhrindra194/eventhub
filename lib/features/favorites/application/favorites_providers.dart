import 'package:eventhub/core/analytics/app_analytics.dart';
import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/core/supabase/supabase_providers.dart';
import 'package:eventhub/features/auth/application/auth_providers.dart';
import 'package:eventhub/features/favorites/data/favorites_remote_data_source.dart';
import 'package:eventhub/features/favorites/data/favorites_repository_impl.dart';
import 'package:eventhub/features/favorites/domain/favorites_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ProviderListenableSelect;
import 'package:riverpod_annotation/riverpod_annotation.dart' hide AsyncResult;

part 'favorites_providers.g.dart';

@Riverpod(keepAlive: true)
FavoritesRepository favoritesRepository(Ref ref) => FavoritesRepositoryImpl(
  FavoritesRemoteDataSource(ref.watch(supabaseClientProvider)),
);

@riverpod
Stream<List<String>> favoriteIds(Ref ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null || !user.isParticipant) return Stream.value(const []);
  return ref.watch(favoritesRepositoryProvider).watchFavoriteIds(user.id);
}

/// Toggles sent but not yet echoed by Realtime: event id → starred.
///
/// Unlike Firestore, Supabase has no local write cache, so the stream only
/// reflects a toggle after the round trip. Overlaying the intent keeps the
/// heart flipping at the tap; an entry is dropped once the stream agrees, or
/// when the write fails.
@Riverpod(keepAlive: true)
class PendingFavorites extends _$PendingFavorites {
  @override
  Map<String, bool> build() {
    ref.listen(favoriteIdsProvider, (_, next) {
      final ids = next.value;
      if (ids == null || state.isEmpty) return;
      final starred = ids.toSet();
      final settled = {
        for (final entry in state.entries)
          if (starred.contains(entry.key) == entry.value) entry.key,
      };
      if (settled.isNotEmpty) {
        state = {
          for (final entry in state.entries)
            if (!settled.contains(entry.key)) entry.key: entry.value,
        };
      }
    });
    return const {};
  }

  // ignore: avoid_positional_boolean_parameters
  void mark(String eventId, bool starred) =>
      state = {...state, eventId: starred};

  void clear(String eventId) => state = {...state}..remove(eventId);
}

@riverpod
bool isFavorite(Ref ref, String eventId) =>
    ref.watch(pendingFavoritesProvider.select((p) => p[eventId])) ??
    ref.watch(favoriteIdsProvider).value?.contains(eventId) ??
    false;

@riverpod
class FavoriteController extends _$FavoriteController {
  @override
  FutureOr<void> build() {}

  /// The heart flips at once (see [PendingFavorites]); a refused write
  /// flips it back and returns the failure for the caller to show.
  Future<Result<void>> toggle(String eventId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return const Err(AuthFailure.notSignedIn());
    final repo = ref.read(favoritesRepositoryProvider);
    final pending = ref.read(pendingFavoritesProvider.notifier);
    final adding = !ref.read(isFavoriteProvider(eventId));
    pending.mark(eventId, adding);
    final result = adding
        ? await repo.add(userId: user.id, eventId: eventId)
        : await repo.remove(userId: user.id, eventId: eventId);
    if (result is Ok<void>) {
      ref.read(appAnalyticsProvider).favorite(eventId, added: adding);
    } else {
      pending.clear(eventId);
    }
    return result;
  }
}
