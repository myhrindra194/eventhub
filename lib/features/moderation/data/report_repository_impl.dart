import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/errors/failure_exception.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/moderation/data/report_remote_data_source.dart';
import 'package:eventhub/features/moderation/domain/report.dart';
import 'package:eventhub/features/moderation/domain/report_repository.dart';

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
  }) async {
    final result = await guard(() async {
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
      await _remote.create(
        reporterId: reporterId,
        target: target,
        targetId: targetId,
        reason: reason,
        details: details.trim(),
      );
    });

    // Reports are write-only: a second report by the same account lands on
    // the existing document, which the rules treat as a (forbidden) update.
    // The client cannot read the document to tell, so permission-denied on
    // this path means "already reported" — and saying so is both true and
    // reassuring.
    if (result case Err(failure: PermissionFailure())) {
      return const Err(
        BusinessRuleFailure(
          rule: BusinessRule.alreadyReported,
          message:
              'Vous avez déjà signalé ce contenu. Il est en cours d’examen.',
        ),
      );
    }
    return result;
  }
}
