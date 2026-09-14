import 'package:eventhub/core/analytics/app_analytics.dart';
import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/firebase/firebase_providers.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/auth/application/auth_providers.dart';
import 'package:eventhub/features/favorites/data/favorites_remote_data_source.dart';
import 'package:eventhub/features/favorites/data/favorites_repository_impl.dart';
import 'package:eventhub/features/favorites/domain/favorites_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' hide AsyncResult;

part 'favorites_providers.g.dart';

@Riverpod(keepAlive: true)
FavoritesRepository favoritesRepository(Ref ref) => FavoritesRepositoryImpl(
  FavoritesRemoteDataSource(ref.watch(firestoreProvider)),
);

@riverpod
Stream<List<String>> favoriteIds(Ref ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null || !user.isParticipant) return Stream.value(const []);
  return ref.watch(favoritesRepositoryProvider).watchFavoriteIds(user.id);
}

@riverpod
bool isFavorite(Ref ref, String eventId) =>
    ref.watch(favoriteIdsProvider).value?.contains(eventId) ?? false;

@riverpod
class FavoriteController extends _$FavoriteController {
  @override
  FutureOr<void> build() {}

  /// Firestore applies the write locally first, so the heart flips at once
  /// even before the server acknowledges it.
  Future<Result<void>> toggle(String eventId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return const Err(AuthFailure.notSignedIn());
    final repo = ref.read(favoritesRepositoryProvider);
    final adding = !ref.read(isFavoriteProvider(eventId));
    final result = adding
        ? await repo.add(userId: user.id, eventId: eventId)
        : await repo.remove(userId: user.id, eventId: eventId);
    if (result is Ok<void>) {
      ref.read(appAnalyticsProvider).favorite(eventId, added: adding);
    }
    return result;
  }
}
