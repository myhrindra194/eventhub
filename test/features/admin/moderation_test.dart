import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/admin/data/moderation_dtos.dart';
import 'package:eventhub/features/admin/data/moderation_remote_data_source.dart';
import 'package:eventhub/features/admin/domain/moderation.dart';
import 'package:eventhub/features/moderation/domain/report.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const reviewId = '6f1c9a52-3b7e-4d0a-9c1e-2b8f0d4e7a11';

  group('ModerationPolicy.actionsFor', () {
    test('offers hide or restore for a review depending on its state', () {
      expect(ModerationPolicy.actionsFor(ReportTarget.review), [
        ModerationAction.hide,
        ModerationAction.dismiss,
      ]);
      expect(
        ModerationPolicy.actionsFor(ReportTarget.review, reviewHidden: true),
        [ModerationAction.restore, ModerationAction.dismiss],
      );
    });

    test(
      'offers removal for an event, suspension or reinstatement for an account',
      () {
        expect(ModerationPolicy.actionsFor(ReportTarget.event), [
          ModerationAction.removeEvent,
          ModerationAction.dismiss,
        ]);
        expect(
          ModerationPolicy.actionsFor(
            ReportTarget.user,
            accountSuspended: true,
          ),
          [ModerationAction.reinstate, ModerationAction.dismiss],
        );
      },
    );

    test('wire values match the moderation_action enum', () {
      expect(ModerationAction.values.map((a) => a.wire).toSet(), {
        'hide',
        'restore',
        'removeEvent',
        'suspend',
        'reinstate',
        'dismiss',
      });
    });
  });

  group('ModerationPolicy validation', () {
    test('requires a note when a person loses something', () {
      expect(
        ModerationPolicy.validateNote(ModerationAction.removeEvent, '  '),
        isA<Err<void>>(),
      );
      expect(
        ModerationPolicy.validateNote(ModerationAction.suspend, 'Fraude.'),
        isA<Ok<void>>(),
      );
      expect(
        ModerationPolicy.validateNote(ModerationAction.dismiss, ''),
        isA<Ok<void>>(),
      );
      expect(
        ModerationPolicy.validateNote(ModerationAction.hide, 'x' * 501),
        isA<Err<void>>(),
      );
    });

    test('checks the email of a new administrator', () {
      expect(ModerationPolicy.validateEmail('a@b.co'), isA<Ok<void>>());
      expect(ModerationPolicy.validateEmail('pas-un-email'), isA<Err<void>>());
    });

    test('derives suspension from the last decision on an account', () {
      ModerationEntry entry(ModerationAction? decision) => ModerationEntry(
        id: 'user_u1',
        target: ReportTarget.user,
        targetId: 'u1',
        reportCount: 2,
        status: ModerationStatus.resolved,
        decision: decision,
      );
      expect(
        ModerationPolicy.isSuspended(entry(ModerationAction.suspend)),
        isTrue,
      );
      expect(
        ModerationPolicy.isSuspended(entry(ModerationAction.reinstate)),
        isFalse,
      );
      expect(ModerationPolicy.isSuspended(null), isFalse);
    });
  });

  group('ModerationEntry ids', () {
    test('compose and parse the id stamped by the database', () {
      final id = ModerationEntry.composeId(ReportTarget.review, reviewId);
      expect(id, 'review_$reviewId');
      expect(ModerationEntry.parseId(id), (ReportTarget.review, reviewId));
      expect(ModerationEntry.parseId('event_abc'), (ReportTarget.event, 'abc'));
    });

    test('rejects unknown types and malformed ids', () {
      expect(ModerationEntry.parseId('comment_x'), isNull);
      expect(ModerationEntry.parseId('event_'), isNull);
      expect(ModerationEntry.parseId('nothing'), isNull);
    });
  });

  group('row mapping', () {
    test('maps a moderation_queue row', () {
      final entry = ModerationRemoteDataSource.entryFromRow({
        'target_type': 'review',
        'target_id': reviewId,
        'id': 'review_$reviewId',
        'report_count': 3,
        'last_reason': 'harassment',
        'status': 'resolved',
        'auto_hidden': true,
        'decision': 'hide',
        'decision_note': 'Insultes.',
        'decided_by': '11111111-2222-4333-8444-555555555555',
        'decided_at': '2026-09-14T09:30:00+00:00',
        'created_at': '2026-09-13T20:00:00+00:00',
        'updated_at': DateTime(2026, 9, 14).toUtc().toIso8601String(),
      });
      expect(entry, isNotNull);
      expect(entry!.id, 'review_$reviewId');
      expect(entry.target, ReportTarget.review);
      expect(entry.targetId, reviewId);
      expect(entry.lastReason, ReportReason.harassment);
      expect(entry.autoHidden, isTrue);
      expect(entry.status, ModerationStatus.resolved);
      expect(entry.decision, ModerationAction.hide);
      expect(entry.decisionNote, 'Insultes.');
      expect(entry.updatedAt, DateTime(2026, 9, 14));
      expect(entry.isOpen, isFalse);
    });

    test('skips a target type the app does not know', () {
      expect(
        ModerationRemoteDataSource.entryFromRow({
          'target_type': 'comment',
          'target_id': 'x',
          'id': 'comment_x',
        }),
        isNull,
      );
    });

    test('never exposes the reporter uuid, only its first group', () {
      final report = ModerationRemoteDataSource.reportFromRow({
        'id': '0f0e0d0c-0b0a-4908-8706-050403020100',
        'target_type': 'review',
        'target_id': reviewId,
        'reason': 'spam',
        'details': 'Liens répétés',
        'reporter_id': 'a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d',
        'created_at': '2026-09-14T08:00:00+00:00',
      });
      expect(report.reporterKey, 'a1b2c3d4');
      expect(report.reason, ReportReason.spam);
      expect(
        ModerationRemoteDataSource.reportFromRow({
          'id': 'r2',
          'reporter_id': null,
        }).reporterKey,
        '',
      );
    });

    test('maps a decision and an administrator', () {
      final decision = ModerationDecisionDto.fromJson({
        'id': 42,
        'target_type': 'user',
        'target_id': 'u1',
        'action': 'suspend',
        'note': 'Fraude.',
        'decided_by': 'admin-uuid',
        'decided_at': '2026-09-14T08:00:00+00:00',
      }).toDomain();
      expect(decision.action, ModerationAction.suspend);
      expect(decision.by, 'admin-uuid');

      final admin = AdminAccountDto.fromJson({
        'user_id': 'admin-uuid',
        'email': 'admin@eventhub.test',
        'name': 'Admin',
        'granted_by': null,
        'granted_at': '2026-09-01T08:00:00+00:00',
      }).toDomain();
      expect(admin.id, 'admin-uuid');
      expect(admin.email, 'admin@eventhub.test');
      expect(admin.grantedBy, isNull);
    });
  });
}
