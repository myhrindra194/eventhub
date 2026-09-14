import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/admin/domain/moderation.dart';
import 'package:eventhub/features/moderation/domain/report.dart';

/// Everything the moderation area reads and decides. Every read is allowed
/// by the rules only with the `admin` claim; every decision goes through a
/// callable Cloud Function that checks the claim again.
abstract interface class ModerationRepository {
  /// Open entries, most reported first; closed ones, most recent first.
  Stream<List<ModerationEntry>> watchQueue({required bool open});

  Stream<ModerationEntry?> watchEntry(String entryId);

  Stream<List<ReportRecord>> watchReports({
    required ReportTarget target,
    required String targetId,
  });

  Stream<List<ModerationDecision>> watchDecisions(String entryId);

  Stream<ReportedAccount?> watchAccount(String userId);

  /// Returns the number of reservations cancelled (event removal), if any.
  AsyncResult<int?> decide({
    required ModerationEntry entry,
    required ModerationAction action,
    required String note,
  });

  Stream<List<AdminAccount>> watchAdmins();

  AsyncResult<void> setAdmin({required String email, required bool admin});
}
