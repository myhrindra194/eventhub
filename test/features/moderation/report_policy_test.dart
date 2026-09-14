import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/moderation/domain/report.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Result<void> validate({
    ReportTarget target = ReportTarget.event,
    String targetId = 'e1',
    ReportReason? reason = ReportReason.misleading,
    String details = '',
    String reporterId = 'p1',
  }) => ReportPolicy.validate(
    reporterId: reporterId,
    target: target,
    targetId: targetId,
    reason: reason,
    details: details,
  );

  test('composes the one-report-per-account id the rules expect', () {
    expect(
      ReportPolicy.composeId(
        target: ReportTarget.review,
        targetId: 'e1_p2',
        reporterId: 'p1',
      ),
      'review_e1_p2_p1',
    );
  });

  test('wire values match the list accepted by firestore.rules', () {
    expect(ReportReason.values.map((r) => r.wire).toSet(), {
      'spam',
      'misleading',
      'inappropriate',
      'fraud',
      'harassment',
      'other',
    });
    expect(ReportTarget.values.map((t) => t.name).toSet(), {
      'event',
      'user',
      'review',
    });
  });

  test('accepts a reasoned report', () {
    expect(validate(), isA<Ok<void>>());
  });

  test('requires a reason, and details when the reason is "other"', () {
    expect(validate(reason: null), isA<Err<void>>());
    expect(validate(reason: ReportReason.other), isA<Err<void>>());
    expect(
      validate(reason: ReportReason.other, details: 'Doublon'),
      isA<Ok<void>>(),
    );
  });

  test('refuses reporting oneself or one’s own review', () {
    for (final result in [
      validate(target: ReportTarget.user, targetId: 'p1'),
      validate(target: ReportTarget.review, targetId: 'e1_p1'),
    ]) {
      expect(
        result,
        isA<Err<void>>().having(
          (e) => (e.failure as BusinessRuleFailure).rule,
          'rule',
          BusinessRule.cannotReportSelf,
        ),
      );
    }
    expect(
      validate(target: ReportTarget.review, targetId: 'e1_p2'),
      isA<Ok<void>>(),
    );
  });

  test('bounds the narrative at 2 000 characters', () {
    expect(validate(details: 'x' * 2001), isA<Err<void>>());
    expect(validate(details: 'x' * 2000), isA<Ok<void>>());
  });
}
