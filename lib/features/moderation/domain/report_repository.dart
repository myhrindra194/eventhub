import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/moderation/domain/report.dart';

/// `public.reports` — write-only for clients, one report per account per
/// target (a UNIQUE constraint).
abstract interface class ReportRepository {
  /// A second report of the same target by the same account fails with
  /// [BusinessRule.alreadyReported]. [reporterId] feeds the local checks;
  /// the database takes the reporter from the session.
  AsyncResult<void> submit({
    required String reporterId,
    required ReportTarget target,
    required String targetId,
    required ReportReason reason,
    required String details,
  });
}
