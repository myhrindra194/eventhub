import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/organizers/data/organizer_directory_remote_data_source.dart';
import 'package:eventhub/features/organizers/domain/organizer_profile.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixtures.dart';

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

  group('profileFromFirestore', () {
    test('maps counters, bio and member date', () {
      final profile =
          OrganizerDirectoryRemoteDataSource.profileFromFirestore('o1', {
            'name': 'Mirindra',
            'bio': 'Meetups Flutter.',
            'followerCount': 12,
            'eventCount': 4,
            'ratingSum': 9,
            'ratingCount': 2,
            'memberSince': Timestamp.fromDate(DateTime(2025, 3)),
          });
      expect(profile.name, 'Mirindra');
      expect(profile.hasBio, isTrue);
      expect(profile.followerCount, 12);
      expect(profile.eventCount, 4);
      expect(profile.averageRating, 4.5);
      expect(profile.memberSince, DateTime(2025, 3));
    });

    test('defaults missing fields and never shows a negative counter', () {
      final profile = OrganizerDirectoryRemoteDataSource.profileFromFirestore(
        'o1',
        {'name': 'M', 'followerCount': -1},
      );
      expect(profile.bio, '');
      expect(profile.hasBio, isFalse);
      expect(profile.followerCount, 0);
      expect(profile.memberSince, isNull);
    });
  });
}
