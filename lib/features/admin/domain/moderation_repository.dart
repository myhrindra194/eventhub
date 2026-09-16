import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/admin/domain/moderation.dart';
import 'package:eventhub/features/moderation/domain/report.dart';

/// Tout ce que l’espace de modération lit et décide. Chaque lecture est
/// réservée aux seuls administrateurs (`admins/{uid}`), et chaque décision est
/// un lot que les règles recontrôlent écriture par écriture.
abstract interface class ModerationRepository {
  /// Entrées ouvertes, les plus signalées d’abord ; entrées fermées, les plus
  /// récentes d’abord.
  Stream<List<ModerationEntry>> watchQueue({required bool open});

  Stream<ModerationEntry?> watchEntry(String entryId);

  Stream<List<ReportRecord>> watchReports({
    required ReportTarget target,
    required String targetId,
  });

  Stream<List<ModerationDecision>> watchDecisions(String entryId);

  Stream<ReportedAccount?> watchAccount(String userId);

  /// Renvoie le nombre de réservations annulées (retrait d’un événement), le
  /// cas échéant.
  AsyncResult<int?> decide({
    required ModerationEntry entry,
    required ModerationAction action,
    required String note,
  });

  /// Qui détient le rôle. L’attribution et le retrait se font dans la console
  /// Firebase : `admins/{uid}` n’est écrivable par aucun client, si bien
  /// qu’aucun compte compromis ne peut jamais se promouvoir lui-même.
  Stream<List<AdminAccount>> watchAdmins();
}
