import 'package:cloud_firestore/cloud_firestore.dart' show FirebaseException;
import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/moderation/data/report_remote_data_source.dart';
import 'package:eventhub/features/moderation/data/report_repository_impl.dart';
import 'package:eventhub/features/moderation/domain/report.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tient lieu des deux documents que la vraie source de données écrit
/// ensemble.
class _FakeReports implements ReportRemoteDataSource {
  _FakeReports([this.error]);

  final FirebaseException? error;
  Map<String, String>? written;

  @override
  Future<void> create({
    required ReportTarget target,
    required String targetId,
    required ReportReason reason,
    required String details,
  }) async {
    if (error case final e?) throw e;
    written = {
      'targetType': target.name,
      'targetId': targetId,
      'reason': reason.wire,
      'details': details,
    };
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const reviewId = 'evt-1_user-9';

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

  test('wire values match the lists the security rules accept', () {
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

  test(
    'refuses reporting oneself; review authorship is the rules’ business',
    () {
      expect(
        validate(target: ReportTarget.user, targetId: 'p1'),
        isA<Err<void>>().having(
          (e) => (e.failure as BusinessRuleFailure).rule,
          'rule',
          BusinessRule.cannotReportSelf,
        ),
      );
      // L'identifiant d'un avis se termine par l'uid de son auteur, et les
      // règles refusent le signalement de son propre avis ; le client ne
      // duplique pas cette vérification.
      expect(
        validate(target: ReportTarget.review, targetId: reviewId),
        isA<Ok<void>>(),
      );
    },
  );

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

    test('writes exactly the report fields, details trimmed', () async {
      final remote = _FakeReports();
      expect(await submit(remote), isA<Ok<void>>());
      expect(remote.written, {
        'targetType': 'review',
        'targetId': reviewId,
        'reason': 'spam',
        'details': 'Liens répétés',
      });
    });

    test('a second report by the same account is alreadyReported', () async {
      final result = await submit(
        _FakeReports(
          FirebaseException(
            plugin: 'cloud_firestore',
            code: 'permission-denied',
          ),
        ),
      );
      expect(
        result.failureOrNull,
        isA<BusinessRuleFailure>().having(
          (f) => f.rule,
          'rule',
          BusinessRule.alreadyReported,
        ),
      );
    });

    test('any other backend error keeps its own mapping', () async {
      final result = await submit(
        _FakeReports(
          FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
        ),
      );
      expect(result.failureOrNull, isA<NetworkFailure>());
    });

    test('a local refusal never reaches the backend', () async {
      final remote = _FakeReports();
      final result = await ReportRepositoryImpl(remote).submit(
        reporterId: 'p1',
        target: ReportTarget.user,
        targetId: 'p1',
        reason: ReportReason.spam,
        details: '',
      );
      expect(result, isA<Err<void>>());
      expect(remote.written, isNull);
    });
  });
}
