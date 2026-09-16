import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/moderation/domain/report.dart';

/// `public.reports` — en écriture seule pour les clients, un signalement par
/// compte et par cible (une contrainte UNIQUE).
abstract interface class ReportRepository {
  /// Un second signalement de la même cible par le même compte échoue avec
  /// [BusinessRule.alreadyReported]. [reporterId] alimente les contrôles
  /// locaux ; la base de données, elle, prend l’auteur dans la session.
  AsyncResult<void> submit({
    required String reporterId,
    required ReportTarget target,
    required String targetId,
    required ReportReason reason,
    required String details,
  });
}
