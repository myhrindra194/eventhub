import 'package:cloud_firestore/cloud_firestore.dart' show FirebaseException;
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
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') rethrow;
      // La source de données a déjà tenté les deux formes de l’écriture, et
      // `ReportPolicy` a validé tout ce qu’un client peut vérifier. Il ne
      // reste que la règle que l’identifiant encode lui-même — un signalement
      // par personne et par cible — parce qu’un document de signalement ne
      // peut jamais être écrit deux fois. Le dire est à la fois exact et
      // rassurant : le comptage automatique suit les personnes, pas les clics.
      throw FailureException(
        BusinessRuleFailure(
          rule: BusinessRule.alreadyReported,
          message:
              'Vous avez déjà signalé ce contenu. Il est en cours d’examen.',
          cause: e,
        ),
      );
    }
  });
}
