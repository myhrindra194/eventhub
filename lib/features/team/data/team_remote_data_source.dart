import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:eventhub/core/firebase/firestore_paths.dart';
import 'package:eventhub/features/team/domain/team.dart';

class TeamRemoteDataSource {
  TeamRemoteDataSource(FirebaseFirestore firestore, this._functions)
    : _events = firestore.collection(FirestorePaths.events),
      _users = firestore.collection(FirestorePaths.users);

  final CollectionReference<Map<String, dynamic>> _events;
  final CollectionReference<Map<String, dynamic>> _users;
  final FirebaseFunctions _functions;

  Stream<List<StaffInvitation>> watchPendingForEvent(String eventId) =>
      _pending(_events.doc(eventId).collection('invitations'));

  Stream<List<StaffInvitation>> watchPendingForUser(String userId) =>
      _pending(_users.doc(userId).collection('staffInvitations'));

  Stream<List<StaffInvitation>> _pending(
    CollectionReference<Map<String, dynamic>> collection,
  ) => collection
      .where('status', isEqualTo: 'pending')
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((s) => [for (final d in s.docs) invitationFromFirestore(d.data())]);

  Future<void> invite({required String eventId, required String email}) =>
      _functions.httpsCallable('inviteCoOrganizer').call<Object?>({
        'eventId': eventId,
        'email': email,
      });

  Future<void> respond({required String eventId, required bool accept}) =>
      _functions.httpsCallable('respondToStaffInvite').call<Object?>({
        'eventId': eventId,
        'accept': accept,
      });

  Future<void> remove({required String eventId, required String userId}) =>
      _functions.httpsCallable('removeCoOrganizer').call<Object?>({
        'eventId': eventId,
        'userId': userId,
      });

  static StaffInvitation invitationFromFirestore(Map<String, dynamic> data) {
    DateTime? time(String key) => switch (data[key]) {
      final Timestamp t => t.toDate(),
      _ => null,
    };
    return StaffInvitation(
      eventId: data['eventId'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      email: data['email'] as String? ?? '',
      name: data['name'] as String? ?? '',
      invitedByName: data['invitedByName'] as String? ?? '',
      eventTitle: data['eventTitle'] as String? ?? '',
      eventStartsAt: time('eventStartsAt'),
      status: InvitationStatus.fromWire(data['status']),
      createdAt: time('createdAt'),
    );
  }
}
