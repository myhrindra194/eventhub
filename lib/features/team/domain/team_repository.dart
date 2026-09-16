import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/team/domain/team.dart';

/// Invitations de co-organisateurs et appartenance à l’équipe (F-16). Les
/// lectures sont des flux Realtime ; chaque changement passe par une fonction
/// de base de données.
abstract interface class TeamRepository {
  /// Invitations en attente d’un événement, pour son équipe.
  Stream<List<StaffInvitation>> watchPendingForEvent(String eventId);

  /// Invitations en attente adressées à [userId].
  Stream<List<StaffInvitation>> watchPendingForUser(String userId);

  AsyncResult<void> invite({required String eventId, required String email});

  AsyncResult<void> respond({required String eventId, required bool accept});

  /// Retire un membre ou annule une invitation en attente ; un membre peut
  /// passer son propre identifiant pour quitter l’équipe.
  AsyncResult<void> remove({required String eventId, required String userId});
}
