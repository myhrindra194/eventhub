import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/admin/data/moderation_dtos.dart';
import 'package:eventhub/features/admin/data/moderation_remote_data_source.dart';
import 'package:eventhub/features/admin/domain/moderation.dart';
import 'package:eventhub/features/moderation/domain/report.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const reviewId = 'evt-1_user-9';

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

    test('every action has a wire value the decisions history can store', () {
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

  group('ModerationPolicy.validateNote', () {
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
  });

  group('ModerationEntry ids', () {
    test('compose and parse the id the rules rebuild', () {
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

  group('document mapping', () {
    test('maps a moderationQueue document, id apart', () {
      final entry = ModerationRemoteDataSource.entryFrom('review_$reviewId', {
        'targetType': 'review',
        'targetId': reviewId,
        'reportCount': 3,
        'lastReason': 'harassment',
        'status': 'resolved',
        'decision': 'hide',
        'decisionNote': 'Insultes.',
        'decidedBy': 'admin-1',
        'decidedAt': Timestamp.fromDate(DateTime(2026, 9, 14, 9, 30)),
        'updatedAt': Timestamp.fromDate(DateTime(2026, 9, 14)),
      });

      expect(entry, isNotNull);
      expect(entry!.id, 'review_$reviewId');
      expect(entry.target, ReportTarget.review);
      expect(entry.targetId, reviewId);
      expect(entry.lastReason, ReportReason.harassment);
      expect(entry.status, ModerationStatus.resolved);
      expect(entry.decision, ModerationAction.hide);
      expect(entry.decisionNote, 'Insultes.');
      expect(entry.updatedAt, DateTime(2026, 9, 14));
      expect(entry.isOpen, isFalse);
    });

    test('skips a target type the app does not know', () {
      expect(
        ModerationRemoteDataSource.entryFrom('comment_x', {
          'targetType': 'comment',
          'targetId': 'x',
        }),
        isNull,
      );
    });

    test('never exposes the reporter id, only its first characters', () {
      final report = ModerationRemoteDataSource.reportFrom(
        'review_${reviewId}_a1b2c3d4e5f6',
        {
          'targetType': 'review',
          'targetId': reviewId,
          'reason': 'spam',
          'details': 'Liens répétés',
          'reporterId': 'a1b2c3d4e5f6g7h8',
          'createdAt': Timestamp.fromDate(DateTime(2026, 9, 14, 8)),
        },
      );
      expect(report.reporterKey, 'a1b2c3d4');
      expect(report.reason, ReportReason.spam);
      expect(
        ModerationRemoteDataSource.reportFrom('r2', {
          'reporterId': null,
        }).reporterKey,
        '',
      );
    });

    test('maps a decision and an administrator', () {
      final decision = ModerationDecisionDto.fromJson({
        'action': 'suspend',
        'note': 'Fraude.',
        'by': 'admin-1',
        'at': Timestamp.fromDate(DateTime(2026, 9, 14, 8)),
      }).toDomain();
      expect(decision.action, ModerationAction.suspend);
      expect(decision.by, 'admin-1');

      final admin = AdminAccountDto.fromFirestore('admin-1', {
        'email': 'admin@eventhub.test',
        'name': 'Admin',
        'grantedAt': Timestamp.fromDate(DateTime(2026, 9)),
      }).toDomain();
      expect(admin.id, 'admin-1');
      expect(admin.email, 'admin@eventhub.test');
      expect(admin.grantedAt, DateTime(2026, 9));
    });

    test('reads the suspension from the account itself', () {
      final account = ReportedAccountDto.fromFirestore('user-1', {
        'name': 'Soa',
        'email': 'soa@example.com',
        'role': 'organizer',
        'suspended': true,
        'createdAt': Timestamp.fromDate(DateTime(2026, 8)),
      }).toDomain();
      expect(account.suspended, isTrue);
      expect(account.role, 'organizer');

      final active = ReportedAccountDto.fromFirestore('user-2', {
        'name': 'Hery',
        'email': 'hery@example.com',
        'role': 'participant',
      }).toDomain();
      expect(active.suspended, isFalse);
    });
  });
}
