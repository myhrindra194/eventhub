import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/favorites/data/favorites_remote_data_source.dart';
import 'package:eventhub/features/favorites/data/favorites_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements FavoritesRemoteDataSource {}

void main() {
  late _MockRemote remote;
  late FavoritesRepositoryImpl repo;

  setUp(() {
    remote = _MockRemote();
    repo = FavoritesRepositoryImpl(remote);
  });

  test('stars and unstars under the signed-in user', () async {
    when(() => remote.add('user-1', 'evt-1')).thenAnswer((_) async {});
    when(() => remote.remove('user-1', 'evt-1')).thenAnswer((_) async {});

    expect(await repo.add(userId: 'user-1', eventId: 'evt-1'), isA<Ok<void>>());
    expect(
      await repo.remove(userId: 'user-1', eventId: 'evt-1'),
      isA<Ok<void>>(),
    );
    verify(() => remote.add('user-1', 'evt-1')).called(1);
    verify(() => remote.remove('user-1', 'evt-1')).called(1);
  });

  test('a refused write becomes a PermissionFailure', () async {
    when(() => remote.add('user-1', 'evt-1')).thenThrow(
      FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
    );
    expect(
      await repo.add(userId: 'user-1', eventId: 'evt-1'),
      isA<Err<void>>().having(
        (e) => e.failure,
        'failure',
        isA<PermissionFailure>(),
      ),
    );
  });

  test('streams the ids from the data source', () {
    when(
      () => remote.watchIds('user-1'),
    ).thenAnswer((_) => Stream.value(const ['evt-2', 'evt-1']));
    expect(repo.watchFavoriteIds('user-1'), emits(['evt-2', 'evt-1']));
  });
}
