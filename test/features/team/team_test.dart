import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/auth/domain/entities/app_user.dart';
import 'package:eventhub/features/auth/domain/entities/user_role.dart';
import 'package:eventhub/features/events/domain/policies/event_policy.dart';
import 'package:eventhub/features/team/data/team_remote_data_source.dart';
import 'package:eventhub/features/team/domain/team.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixtures.dart';

void main() {
  const owner = Fixtures.organizer; // org-1
  const helper = AppUser(
    id: 'org-2',
    name: 'Hery',
    email: 'hery@example.com',
    role: UserRole.organizer,
  );
  const outsider = AppUser(
    id: 'org-3',
    name: 'Soa',
    email: 'soa@example.com',
    role: UserRole.organizer,
  );

  BusinessRule? rule(Result<void> result) => switch (result) {
    Err(failure: final BusinessRuleFailure f) => f.rule,
    _ => null,
  };

  group('EventPolicy with a team', () {
    final event = Fixtures.event(staffIds: const ['org-2']);

    test('lets owner and co-organizer manage, not an outsider', () {
      expect(EventPolicy.canManage(event: event, user: owner), isA<Ok<void>>());
      expect(
        EventPolicy.canManage(event: event, user: helper),
        isA<Ok<void>>(),
      );
      expect(
        rule(EventPolicy.canManage(event: event, user: outsider)),
        BusinessRule.notEventOwner,
      );
    });

    test('keeps deletion and the team with the owner', () {
      expect(EventPolicy.canDelete(event: event, user: owner), isA<Ok<void>>());
      expect(
        rule(EventPolicy.canDelete(event: event, user: helper)),
        BusinessRule.notEventOwner,
      );
      expect(
        rule(EventPolicy.canManageTeam(event: event, user: helper)),
        BusinessRule.notEventOwner,
      );
    });

    test('a participant listed by mistake manages nothing', () {
      expect(
        rule(
          EventPolicy.canManage(
            event: Fixtures.event(staffIds: const ['user-1']),
            user: Fixtures.participant,
          ),
        ),
        BusinessRule.notEventOwner,
      );
    });
  });

  group('TeamPolicy.canInvite', () {
    Result<void> invite({
      List<String> staff = const [],
      String email = 'hery@example.com',
      int pending = 0,
      DateTime? startsAt,
      AppUser user = owner,
    }) => TeamPolicy.canInvite(
      event: Fixtures.event(staffIds: staff, startsAt: startsAt),
      user: user,
      email: email,
      pendingCount: pending,
      now: Fixtures.now,
    );

    test('accepts a valid invitation from the owner', () {
      expect(invite(), isA<Ok<void>>());
    });

    test('refuses a co-organizer inviting, a bad or own email', () {
      expect(
        rule(invite(staff: const ['org-2'], user: helper)),
        BusinessRule.notEventOwner,
      );
      expect(invite(email: 'pas-un-email'), isA<Err<void>>());
      expect(invite(email: ' Mirindra@Example.com '), isA<Err<void>>());
    });

    test(
      'refuses a past event and a full team, pending invitations included',
      () {
        expect(
          rule(
            invite(startsAt: Fixtures.now.subtract(const Duration(hours: 1))),
          ),
          BusinessRule.eventAlreadyStarted,
        );
        expect(
          rule(invite(staff: List.generate(8, (i) => 'o$i'), pending: 2)),
          BusinessRule.actionRefused,
        );
        expect(
          invite(staff: List.generate(8, (i) => 'o$i'), pending: 1),
          isA<Ok<void>>(),
        );
      },
    );
  });

  test('maps an invitation document', () {
    final invitation = TeamRemoteDataSource.invitationFromFirestore({
      'eventId': 'e1',
      'userId': 'org-2',
      'email': 'hery@example.com',
      'name': 'Hery',
      'invitedByName': 'Mirindra',
      'eventTitle': 'Flutter Meetup',
      'eventStartsAt': Timestamp.fromDate(DateTime(2026, 10, 2, 18)),
      'status': 'pending',
    });
    expect(invitation.isPending, isTrue);
    expect(invitation.eventStartsAt, DateTime(2026, 10, 2, 18));
    expect(invitation.invitedByName, 'Mirindra');
    expect(
      TeamRemoteDataSource.invitationFromFirestore({
        'status': 'accepted',
      }).status,
      InvitationStatus.accepted,
    );
  });
}
