import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/moderation/domain/report.dart';

/// `reports/{targetType}_{targetId}_{reporterId}` — write-only for clients.
abstract interface class ReportRepository {
  /// A second report of the same target by the same account fails with
  /// [BusinessRule.alreadyReported].
  AsyncResult<void> submit({
    required String reporterId,
    required ReportTarget target,
    required String targetId,
    required ReportReason reason,
    required String details,
  });
}
