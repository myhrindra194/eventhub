import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/waitlist/data/waitlist_remote_data_source.dart';
import 'package:eventhub/features/waitlist/data/waitlist_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fixtures.dart';

class _MockRemote extends Mock implements WaitlistRemoteDataSource {}

void main() {
  late _MockRemote remote;
  late WaitlistRepositoryImpl repository;

  setUp(() {
    remote = _MockRemote();
    repository = WaitlistRepositoryImpl(remote);
    when(() => remote.join(any(), any())).thenAnswer((_) async {});
    when(() => remote.leave(any(), any())).thenAnswer((_) async {});
  });

  test('joins the queue of a full event under the caller\'s own uid', () async {
    final result = await repository.join(
      event: Fixtures.event(availablePlaces: 0),
      user: Fixtures.participant,
      reservation: null,
      now: Fixtures.now,
    );
    expect(result, isA<Ok<void>>());
    verify(() => remote.join('evt-1', Fixtures.participant.id)).called(1);
  });

  test('a refusal by the policy writes nothing', () async {
    final result = await repository.join(
      event: Fixtures.event(),
      user: Fixtures.participant,
      reservation: null,
      now: Fixtures.now,
    );
    expect(
      (result.failureOrNull! as BusinessRuleFailure).rule,
      BusinessRule.waitlistNotAvailable,
    );
    verifyNever(() => remote.join(any(), any()));
  });

  test('leaving removes only the caller\'s entry', () async {
    await repository.leave(eventId: 'evt-1', userId: 'user-1');
    verify(() => remote.leave('evt-1', 'user-1')).called(1);
  });
}
