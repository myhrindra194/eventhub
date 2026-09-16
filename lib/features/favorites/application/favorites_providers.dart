import 'package:eventhub/core/analytics/app_analytics.dart';
import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/firebase/firebase_providers.dart';
import 'package:eventhub/core/result/result.dart';
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
  FavoritesRemoteDataSource(ref.watch(firestoreProvider)),
);

@riverpod
Stream<List<String>> favoriteIds(Ref ref) {
  final user = ref.watch(currentUserProvider);
  // Tout compte est participant, organisateurs compris (un compte, deux
  // espaces) : quiconque est connecté conserve ses favoris.
  if (user == null) return Stream.value(const []);
  return ref.watch(favoritesRepositoryProvider).watchFavoriteIds(user.id);
}

/// Bascules envoyées mais pas encore reflétées par le listener :
/// id d’événement → mis en favori.
///
/// Firestore rend une écriture locale visible immédiatement, mais mettre en
/// favori lit d’abord le document (les règles refusent un `set` par-dessus
/// un favori existant) : l’écriture — et donc le listener — accusent ce
/// temps d’aller-retour. Superposer l’intention garde le cœur qui bascule
/// dès la tape ; une entrée est retirée dès que le flux confirme, ou quand
/// l’écriture échoue.
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

  /// Le cœur bascule immédiatement (voir [PendingFavorites]) ; une écriture
  /// refusée le rebascule et renvoie l’échec, à charge pour l’appelant de
  /// l’afficher.
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
