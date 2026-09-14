import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/team/domain/team.dart';

/// Co-organizer invitations and membership (F-16). Reads come from
/// Firestore; every change goes through a Cloud Function.
abstract interface class TeamRepository {
  /// Pending invitations of an event, for its team.
  Stream<List<StaffInvitation>> watchPendingForEvent(String eventId);

  /// Pending invitations addressed to [userId].
  Stream<List<StaffInvitation>> watchPendingForUser(String userId);

  AsyncResult<void> invite({required String eventId, required String email});

  AsyncResult<void> respond({required String eventId, required bool accept});

  /// Removes a member or cancels a pending invitation; a member may pass
  /// their own id to leave.
  AsyncResult<void> remove({required String eventId, required String userId});
}
