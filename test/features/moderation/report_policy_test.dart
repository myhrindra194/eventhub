import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/moderation/data/report_remote_data_source.dart';
import 'package:eventhub/features/moderation/data/report_repository_impl.dart';
import 'package:eventhub/features/moderation/domain/report.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Throws what `public.reports` would answer for the insert.
class _FakeReports implements ReportRemoteDataSource {
  _FakeReports([this.error]);

  final PostgrestException? error;
  Map<String, String>? inserted;

  @override
  Future<void> create({
    required ReportTarget target,
    required String targetId,
    required ReportReason reason,
    required String details,
  }) async {
    if (error case final e?) throw e;
    inserted = {
      'target_type': target.name,
      'target_id': targetId,
      'reason': reason.wire,
      'details': details,
    };
  }
}

void main() {
  const reviewId = '6f1c9a52-3b7e-4d0a-9c1e-2b8f0d4e7a11';

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

  test('wire values match the report_reason and report_target enums', () {
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

  test('refuses reporting oneself; review authorship is the server’s', () {
    expect(
      validate(target: ReportTarget.user, targetId: 'p1'),
      isA<Err<void>>().having(
        (e) => (e.failure as BusinessRuleFailure).rule,
        'rule',
        BusinessRule.cannotReportSelf,
      ),
    );
    // A review id is an opaque uuid: nothing local says who wrote it.
    expect(
      validate(target: ReportTarget.review, targetId: reviewId),
      isA<Ok<void>>(),
    );
  });

  test('bounds the narrative at 2 000 characters', () {
    expect(validate(details: 'x' * 2001), isA<Err<void>>());
    expect(validate(details: 'x' * 2000), isA<Ok<void>>());
  });

  group('ReportRepositoryImpl.submit', () {
    Future<Result<void>> submit(_FakeReports remote) =>
        ReportRepositoryImpl(remote).submit(
          reporterId: 'p1',
          target: ReportTarget.review,
          targetId: reviewId,
          reason: ReportReason.spam,
          details: '  Liens répétés  ',
        );

    BusinessRule? rule(Result<void> r) => switch (r) {
      Err(failure: final BusinessRuleFailure f) => f.rule,
      _ => null,
    };

    test('inserts only the client columns, details trimmed', () async {
      final remote = _FakeReports();
      expect(await submit(remote), isA<Ok<void>>());
      expect(remote.inserted, {
        'target_type': 'review',
        'target_id': reviewId,
        'reason': 'spam',
        'details': 'Liens répétés',
      });
    });

    test('a second report by the same account is alreadyReported', () async {
      final result = await submit(
        _FakeReports(
          const PostgrestException(
            message: 'duplicate key value violates unique constraint',
            code: '23505',
          ),
        ),
      );
      expect(rule(result), BusinessRule.alreadyReported);
    });

    test('keeps the rule raised by the trigger', () async {
      final result = await submit(
        _FakeReports(
          const PostgrestException(
            message: 'Vous ne pouvez pas signaler votre propre avis.',
            code: 'PT409',
            hint: 'cannotReportSelf',
          ),
        ),
      );
      expect(rule(result), BusinessRule.cannotReportSelf);
      expect(
        result.failureOrNull?.message,
        'Vous ne pouvez pas signaler votre propre avis.',
      );
    });

    test('"other" without details refused by the trigger is a validation '
        'failure', () async {
      final result = await submit(
        _FakeReports(
          const PostgrestException(
            message: 'Certains champs sont invalides.',
            code: 'PT422',
            hint: 'validation',
            details: '{"details": "Précisez ce qui ne va pas."}',
          ),
        ),
      );
      expect(
        result.failureOrNull,
        isA<ValidationFailure>().having(
          (f) => f.fieldErrors['details'],
          'details',
          'Précisez ce qui ne va pas.',
        ),
      );
    });
  });
}
