import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/checkin/domain/check_in_policy.dart';

/// `events/{eventId}/checkins/{reservationId}` — une entrée par billet
/// admis, lisible et écrivable par la seule équipe de l’événement, jamais
/// mise à jour ni supprimée.
abstract interface class CheckInRepository {
  /// reservationId → heure du premier scan.
  Stream<Map<String, DateTime>> watchCheckIns(String eventId);

  /// Juge le billet et, s’il est valide et inutilisé, enregistre l’entrée
  /// scannée par [scannedBy], en une seule transaction.
  AsyncResult<CheckInVerdict> checkIn({
    required String eventId,
    required String reservationId,
    required String scannedBy,
  });
}
