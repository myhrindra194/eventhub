import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/errors/failure_exception.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/moderation/data/report_remote_data_source.dart';
import 'package:eventhub/features/moderation/domain/report.dart';
import 'package:eventhub/features/moderation/domain/report_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

class ReportRepositoryImpl implements ReportRepository {
  const ReportRepositoryImpl(this._remote);

  final ReportRemoteDataSource _remote;

  @override
  AsyncResult<void> submit({
    required String reporterId,
    required ReportTarget target,
    required String targetId,
    required ReportReason reason,
    required String details,
  }) => guard(() async {
    if (ReportPolicy.validate(
          reporterId: reporterId,
          target: target,
          targetId: targetId,
          reason: reason,
          details: details,
        )
        case Err(:final failure)) {
      throw FailureException(failure);
    }
    try {
      await _remote.create(
        target: target,
        targetId: targetId,
        reason: reason,
        details: details.trim(),
      );
    } on PostgrestException catch (e) {
      // `reports_one_per_reporter`: the automatic threshold counts people,
      // not clicks. Saying so is both true and reassuring. Every other
      // refusal (cannotReportSelf, notFound, validation) already carries its
      // rule and French message from the trigger.
      if (e.code == '23505') {
        throw FailureException(
          BusinessRuleFailure(
            rule: BusinessRule.alreadyReported,
            message:
                'Vous avez déjà signalé ce contenu. Il est en cours d’examen.',
            cause: e,
          ),
        );
      }
      rethrow;
    }
  });
}
