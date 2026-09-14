import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/admin/data/moderation_remote_data_source.dart';
import 'package:eventhub/features/admin/domain/moderation.dart';
import 'package:eventhub/features/moderation/domain/report.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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

    test('wire values match ACTIONS_BY_TARGET in the Cloud Functions', () {
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

  group('ModerationEntry.parseId', () {
    test('splits on the first underscore; review ids keep theirs', () {
      expect(ModerationEntry.parseId('review_e1_p9'), (
        ReportTarget.review,
        'e1_p9',
      ));
      expect(ModerationEntry.parseId('event_abc'), (ReportTarget.event, 'abc'));
    });

    test('rejects unknown types and malformed ids', () {
      expect(ModerationEntry.parseId('comment_x'), isNull);
      expect(ModerationEntry.parseId('event_'), isNull);
      expect(ModerationEntry.parseId('nothing'), isNull);
    });
  });

  group('Firestore mapping', () {
    test('maps a queue entry', () {
      final entry =
          ModerationRemoteDataSource.entryFromFirestore('review_e1_p9', {
            'targetType': 'review',
            'targetId': 'e1_p9',
            'reportCount': 3,
            'lastReason': 'harassment',
            'autoHidden': true,
            'status': 'resolved',
            'decision': 'hide',
            'decisionNote': 'Insultes.',
            'updatedAt': Timestamp.fromDate(DateTime(2026, 9, 14)),
          });
      expect(entry, isNotNull);
      expect(entry!.target, ReportTarget.review);
      expect(entry.targetId, 'e1_p9');
      expect(entry.lastReason, ReportReason.harassment);
      expect(entry.autoHidden, isTrue);
      expect(entry.status, ModerationStatus.resolved);
      expect(entry.decision, ModerationAction.hide);
      expect(entry.isOpen, isFalse);
    });

    test('never exposes the reporter uid, only a short key', () {
      final report = ModerationRemoteDataSource.reportFromFirestore('r1', {
        'reason': 'spam',
        'details': 'Liens répétés',
        'reporterId': 'Xy12AbCdEfGh',
      });
      expect(report.reporterKey, 'Xy12Ab');
      expect(report.reason, ReportReason.spam);
    });
  });
}
