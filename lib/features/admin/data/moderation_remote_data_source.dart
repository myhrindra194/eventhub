import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:eventhub/core/firebase/firestore_paths.dart';
import 'package:eventhub/features/admin/domain/moderation.dart';
import 'package:eventhub/features/moderation/domain/report.dart';

/// Firestore reads of the moderation area and the two admin callables.
class ModerationRemoteDataSource {
  ModerationRemoteDataSource(FirebaseFirestore firestore, this._functions)
    : _queue = firestore.collection(FirestorePaths.moderationQueue),
      _reports = firestore.collection(FirestorePaths.reports),
      _users = firestore.collection(FirestorePaths.users),
      _admins = firestore.collection(FirestorePaths.admins);

  final CollectionReference<Map<String, dynamic>> _queue;
  final CollectionReference<Map<String, dynamic>> _reports;
  final CollectionReference<Map<String, dynamic>> _users;
  final CollectionReference<Map<String, dynamic>> _admins;
  final FirebaseFunctions _functions;

  static const pageSize = 100;

  Stream<List<ModerationEntry>> watchQueue({required bool open}) {
    final query = open
        ? _queue
              .where('status', isEqualTo: 'open')
              .orderBy('reportCount', descending: true)
              .orderBy('updatedAt', descending: true)
        : _queue
              .where('status', whereIn: const ['resolved', 'dismissed'])
              .orderBy('updatedAt', descending: true);
    return query
        .limit(pageSize)
        .snapshots()
        .map(
          (s) => [for (final d in s.docs) ?entryFromFirestore(d.id, d.data())],
        );
  }

  Stream<ModerationEntry?> watchEntry(String entryId) =>
      _queue.doc(entryId).snapshots().map((s) {
        final data = s.data();
        return data == null ? null : entryFromFirestore(s.id, data);
      });

  Stream<List<ReportRecord>> watchReports({
    required ReportTarget target,
    required String targetId,
  }) => _reports
      .where('targetType', isEqualTo: target.name)
      .where('targetId', isEqualTo: targetId)
      .orderBy('createdAt', descending: true)
      .limit(pageSize)
      .snapshots()
      .map(
        (s) => [for (final d in s.docs) reportFromFirestore(d.id, d.data())],
      );

  Stream<List<ModerationDecision>> watchDecisions(String entryId) => _queue
      .doc(entryId)
      .collection('decisions')
      .orderBy('at', descending: true)
      .limit(50)
      .snapshots()
      .map(
        (s) => [
          for (final d in s.docs)
            ModerationDecision(
              action: ModerationAction.fromWire(d.data()['action']),
              note: d.data()['note'] as String? ?? '',
              by: d.data()['by'] as String? ?? '',
              at: _time(d.data()['at']),
            ),
        ],
      );

  Stream<ReportedAccount?> watchAccount(String userId) =>
      _users.doc(userId).snapshots().map((s) {
        final data = s.data();
        if (data == null) return null;
        return ReportedAccount(
          id: s.id,
          name: data['name'] as String? ?? '',
          email: data['email'] as String? ?? '',
          role: data['role'] as String? ?? '',
          createdAt: _time(data['createdAt']),
        );
      });

  Stream<List<AdminAccount>> watchAdmins() => _admins
      .orderBy('grantedAt')
      .limit(pageSize)
      .snapshots()
      .map(
        (s) => [
          for (final d in s.docs)
            AdminAccount(
              id: d.id,
              email: d.data()['email'] as String? ?? '',
              name: d.data()['name'] as String?,
              grantedBy: d.data()['grantedBy'] as String?,
              grantedAt: _time(d.data()['grantedAt']),
            ),
        ],
      );

  Future<int?> moderate({
    required String targetType,
    required String targetId,
    required String action,
    required String note,
  }) async {
    final result = await _functions
        .httpsCallable('moderateContent')
        .call<Map<Object?, Object?>>({
          'targetType': targetType,
          'targetId': targetId,
          'action': action,
          'note': note,
        });
    return (result.data['cancelledReservations'] as num?)?.toInt();
  }

  Future<void> setAdminRole({required String email, required bool admin}) =>
      _functions.httpsCallable('setAdminRole').call<Object?>({
        'email': email,
        'admin': admin,
      });

  static ModerationEntry? entryFromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    final parsed = ModerationEntry.parseId(id);
    if (parsed == null) return null;
    final (target, targetId) = parsed;
    return ModerationEntry(
      id: id,
      target: target,
      targetId: data['targetId'] as String? ?? targetId,
      reportCount: (data['reportCount'] as num?)?.toInt() ?? 0,
      status: ModerationStatus.fromWire(data['status']),
      lastReason: _reason(data['lastReason']),
      autoHidden: data['autoHidden'] == true,
      decision: ModerationAction.fromWire(data['decision']),
      decisionNote: data['decisionNote'] as String?,
      decidedAt: _time(data['decidedAt']),
      updatedAt: _time(data['updatedAt']),
    );
  }

  static ReportRecord reportFromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    final reporter = data['reporterId'] as String? ?? '';
    return ReportRecord(
      id: id,
      reason: _reason(data['reason']),
      details: data['details'] as String? ?? '',
      createdAt: _time(data['createdAt']),
      reporterKey: reporter.length > 6 ? reporter.substring(0, 6) : reporter,
    );
  }

  static ReportReason? _reason(Object? wire) {
    for (final reason in ReportReason.values) {
      if (reason.wire == wire) return reason;
    }
    return null;
  }

  static DateTime? _time(Object? value) => switch (value) {
    final Timestamp t => t.toDate(),
    _ => null,
  };
}
