import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventhub/core/firebase/firestore_paths.dart';
import 'package:eventhub/features/moderation/domain/report.dart';

class ReportRemoteDataSource {
  ReportRemoteDataSource(FirebaseFirestore firestore)
    : _reports = firestore.collection(FirestorePaths.reports);

  final CollectionReference<Map<String, dynamic>> _reports;

  /// Exactly the field set the `create` rule accepts.
  Future<void> create({
    required String reporterId,
    required ReportTarget target,
    required String targetId,
    required ReportReason reason,
    required String details,
  }) => _reports
      .doc(
        ReportPolicy.composeId(
          target: target,
          targetId: targetId,
          reporterId: reporterId,
        ),
      )
      .set({
        'targetType': target.name,
        'targetId': targetId,
        'reason': reason.wire,
        'details': details,
        'reporterId': reporterId,
        'createdAt': FieldValue.serverTimestamp(),
      });
}
