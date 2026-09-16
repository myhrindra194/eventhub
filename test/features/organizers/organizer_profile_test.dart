import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/errors/failure_exception.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/organizers/data/organizer_directory_remote_data_source.dart';
import 'package:eventhub/features/organizers/data/organizer_directory_repository_impl.dart';
import 'package:eventhub/features/organizers/domain/organizer_profile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fixtures.dart';

class _MockDirectory extends Mock
    implements OrganizerDirectoryRemoteDataSource {}

void main() {
  group('OrganizerProfile.averageRating', () {
    test('is null until someone reviewed', () {
      expect(const OrganizerProfile(id: 'o', name: 'M').averageRating, isNull);
    });

    test('averages the visible ratings', () {
      expect(
        const OrganizerProfile(
          id: 'o',
          name: 'M',
          ratingSum: 23,
          ratingCount: 5,
        ).averageRating,
        closeTo(4.6, 1e-9),
      );
    });

    test('clamps a counter caught mid-update into 1..5', () {
      expect(
        const OrganizerProfile(
          id: 'o',
          name: 'M',
          ratingSum: 12,
          ratingCount: 2,
        ).averageRating,
        5,
      );
    });
  });

  group('FollowPolicy', () {
    test('lets anyone follow another organizer', () {
      expect(
        FollowPolicy.canFollow(
          user: Fixtures.participant,
          organizerId: 'org-1',
        ),
        isA<Ok<void>>(),
      );
    });

    test('refuses following oneself', () {
      final result = FollowPolicy.canFollow(
        user: Fixtures.organizer,
        organizerId: Fixtures.organizer.id,
      );
      expect(
        result,
        isA<Err<void>>().having(
          (e) => (e.failure as BusinessRuleFailure).rule,
          'rule',
          BusinessRule.cannotFollowSelf,
        ),
      );
    });
  });

  group('profileFrom', () {
    test('maps a Firestore document, id injected', () {
      final profile = OrganizerDirectoryRemoteDataSource.profileFrom('o1', {
        'name': 'Mirindra',
        'bio': 'Meetups Flutter.',
        'followerCount': 12,
        'eventCount': 4,
        'ratingSum': 9,
        'ratingCount': 2,
        'memberSince': DateTime(2025, 3),
        'lastEventId': 'e9',
      });
      expect(profile.id, 'o1');
      expect(profile.name, 'Mirindra');
      expect(profile.hasBio, isTrue);
      expect(profile.followerCount, 12);
      expect(profile.eventCount, 4);
      expect(profile.averageRating, 4.5);
      expect(profile.memberSince, DateTime(2025, 3));
    });

    test('a pending memberSince, missing fields, a negative counter', () {
      final profile = OrganizerDirectoryRemoteDataSource.profileFrom('o1', {
        'name': 'M',
        'bio': null,
        'memberSince': null,
        'followerCount': -1,
      });
      expect(profile.bio, '');
      expect(profile.hasBio, isFalse);
      expect(profile.followerCount, 0);
      expect(profile.memberSince, isNull);
    });
  });

  group('OrganizerDirectoryRepositoryImpl', () {
    late _MockDirectory remote;
    late OrganizerDirectoryRepositoryImpl repo;

    setUp(() {
      remote = _MockDirectory();
      repo = OrganizerDirectoryRepositoryImpl(remote);
    });

    test('follows through the data source', () async {
      when(() => remote.follow('user-1', 'org-1')).thenAnswer((_) async {});
      expect(
        await repo.follow(userId: 'user-1', organizerId: 'org-1'),
        isA<Ok<void>>(),
      );
      verify(() => remote.follow('user-1', 'org-1')).called(1);
    });

    test('refuses following oneself without writing', () async {
      final result = await repo.follow(userId: 'org-1', organizerId: 'org-1');
      expect(
        result,
        isA<Err<void>>().having(
          (e) => (e.failure as BusinessRuleFailure).rule,
          'rule',
          BusinessRule.cannotFollowSelf,
        ),
      );
      verifyNever(() => remote.follow(any(), any()));
    });

    test('surfaces a vanished organizer as not found', () async {
      when(() => remote.follow('user-1', 'gone')).thenThrow(
        const FailureException(
          NotFoundFailure(resource: 'organizers', message: 'Introuvable.'),
        ),
      );
      final result = await repo.follow(userId: 'user-1', organizerId: 'gone');
      expect(
        result,
        isA<Err<void>>().having((e) => e.failure, 'f', isA<NotFoundFailure>()),
      );
    });

    test('unfollows through the data source', () async {
      when(() => remote.unfollow('user-1', 'org-1')).thenAnswer((_) async {});
      expect(
        await repo.unfollow(userId: 'user-1', organizerId: 'org-1'),
        isA<Ok<void>>(),
      );
    });
  });
}
