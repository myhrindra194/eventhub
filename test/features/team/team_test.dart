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

  test('maps a staff_invitations row', () {
    final invitation = TeamRemoteDataSource.invitationFromRow({
      'event_id': '0b6f7c1e-8d2a-4f3b-9e5c-1a2b3c4d5e6f',
      'user_id': '9c8b7a6d-5e4f-4a3b-8c2d-1e0f9a8b7c6d',
      'email': 'hery@example.com',
      'name': 'Hery',
      'invited_by': '11111111-2222-4333-8444-555555555555',
      'invited_by_name': 'Mirindra',
      'event_title': 'Flutter Meetup',
      'event_starts_at': DateTime(2026, 10, 2, 18).toUtc().toIso8601String(),
      'status': 'pending',
      'created_at': '2026-09-14T08:00:00+00:00',
      'responded_at': null,
    });
    expect(invitation.isPending, isTrue);
    expect(invitation.eventId, '0b6f7c1e-8d2a-4f3b-9e5c-1a2b3c4d5e6f');
    expect(invitation.eventStartsAt, DateTime(2026, 10, 2, 18));
    expect(invitation.invitedByName, 'Mirindra');
    expect(
      TeamRemoteDataSource.invitationFromRow({'status': 'accepted'}).status,
      InvitationStatus.accepted,
    );
  });
}
