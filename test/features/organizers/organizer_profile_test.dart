import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/organizers/data/organizer_directory_remote_data_source.dart';
import 'package:eventhub/features/organizers/data/organizer_directory_repository_impl.dart';
import 'package:eventhub/features/organizers/domain/organizer_profile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../helpers/fixtures.dart';

/// Stands in for the Supabase client: each call throws what the database
/// would answer.
class _FakeDirectory implements OrganizerDirectoryRemoteDataSource {
  _FakeDirectory({this.followError});

  final PostgrestException? followError;
  final followed = <String>[];

  @override
  Future<void> follow(String organizerId) async {
    if (followError case final error?) throw error;
    followed.add(organizerId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

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

  group('profileFromRow', () {
    test('maps counters, bio and member date from snake_case columns', () {
      final profile = OrganizerDirectoryRemoteDataSource.profileFromRow({
        'id': 'a4b1c2d3-0000-4000-8000-000000000001',
        'name': 'Mirindra',
        'bio': 'Meetups Flutter.',
        'photo_url': null,
        'follower_count': 12,
        'event_count': 4,
        'rating_sum': 9,
        'rating_count': 2,
        'member_since': DateTime(2025, 3).toUtc().toIso8601String(),
        'suspended': false,
        'updated_at': '2026-09-14T10:00:00+00:00',
      });
      expect(profile.id, 'a4b1c2d3-0000-4000-8000-000000000001');
      expect(profile.name, 'Mirindra');
      expect(profile.hasBio, isTrue);
      expect(profile.followerCount, 12);
      expect(profile.eventCount, 4);
      expect(profile.averageRating, 4.5);
      expect(profile.memberSince, DateTime(2025, 3));
    });

    test('defaults missing fields and never shows a negative counter', () {
      final profile = OrganizerDirectoryRemoteDataSource.profileFromRow({
        'id': 'o1',
        'name': 'M',
        'bio': null,
        'follower_count': -1,
      });
      expect(profile.bio, '');
      expect(profile.hasBio, isFalse);
      expect(profile.followerCount, 0);
      expect(profile.memberSince, isNull);
    });
  });

  group('OrganizerDirectoryRepositoryImpl.follow', () {
    Future<Result<void>> follow(PostgrestException? error) =>
        OrganizerDirectoryRepositoryImpl(
          _FakeDirectory(followError: error),
        ).follow(userId: 'user-1', organizerId: 'org-1');

    test('inserts the follow', () async {
      final remote = _FakeDirectory();
      final result = await OrganizerDirectoryRepositoryImpl(
        remote,
      ).follow(userId: 'user-1', organizerId: 'org-1');
      expect(result, isA<Ok<void>>());
      expect(remote.followed, ['org-1']);
    });

    test('treats an existing follow as done', () async {
      expect(
        await follow(const PostgrestException(message: 'dup', code: '23505')),
        isA<Ok<void>>(),
      );
    });

    test('turns the not-self constraint into cannotFollowSelf', () async {
      final result = await follow(
        const PostgrestException(message: 'check', code: '23514'),
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
}
