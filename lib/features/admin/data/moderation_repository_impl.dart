import 'package:eventhub/core/errors/failure_exception.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/admin/data/moderation_remote_data_source.dart';
import 'package:eventhub/features/admin/domain/moderation.dart';
import 'package:eventhub/features/admin/domain/moderation_repository.dart';
import 'package:eventhub/features/moderation/domain/report.dart';

class ModerationRepositoryImpl implements ModerationRepository {
  const ModerationRepositoryImpl(this._remote);

  final ModerationRemoteDataSource _remote;

  @override
  Stream<List<ModerationEntry>> watchQueue({required bool open}) =>
      _remote.watchQueue(open: open);

  @override
  Stream<ModerationEntry?> watchEntry(String entryId) =>
      _remote.watchEntry(entryId);

  @override
  Stream<List<ReportRecord>> watchReports({
    required ReportTarget target,
    required String targetId,
  }) => _remote.watchReports(target: target, targetId: targetId);

  @override
  Stream<List<ModerationDecision>> watchDecisions(String entryId) =>
      _remote.watchDecisions(entryId);

  @override
  Stream<ReportedAccount?> watchAccount(String userId) =>
      _remote.watchAccount(userId);

  @override
  AsyncResult<int?> decide({
    required ModerationEntry entry,
    required ModerationAction action,
    required String note,
  }) => guard(() async {
    if (ModerationPolicy.validateNote(action, note) case Err(:final failure)) {
      throw FailureException(failure);
    }
    return _remote.moderate(
      targetType: entry.target.name,
      targetId: entry.targetId,
      action: action.wire,
      note: note.trim(),
    );
  });

  @override
  Stream<List<AdminAccount>> watchAdmins() => _remote.watchAdmins();

  @override
  AsyncResult<void> setAdmin({required String email, required bool admin}) =>
      guard(() async {
        if (ModerationPolicy.validateEmail(email) case Err(:final failure)) {
          throw FailureException(failure);
        }
        await _remote.setAdminRole(
          email: email.trim().toLowerCase(),
          admin: admin,
        );
      });
}
