import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/favorites/data/favorites_remote_data_source.dart';
import 'package:eventhub/features/favorites/domain/favorites_repository.dart';

class FavoritesRepositoryImpl implements FavoritesRepository {
  const FavoritesRepositoryImpl(this._remote);

  final FavoritesRemoteDataSource _remote;

  @override
  Stream<List<String>> watchFavoriteIds(String userId) =>
      _remote.watchIds(userId);

  /// [userId] must be the signed-in user: the rules only open one's own
  /// `users/{uid}/favorites`.
  @override
  AsyncResult<void> add({required String userId, required String eventId}) =>
      guard(() => _remote.add(userId, eventId));

  @override
  AsyncResult<void> remove({required String userId, required String eventId}) =>
      guard(() => _remote.remove(userId, eventId));
}
