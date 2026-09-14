import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventhub/core/firebase/firestore_paths.dart';
import 'package:eventhub/features/auth/domain/entities/app_user.dart';

/// `events/{eventId}/waitlist/{userId}`.
class WaitlistRemoteDataSource {
  WaitlistRemoteDataSource(FirebaseFirestore firestore)
    : _events = firestore.collection(FirestorePaths.events);

  final CollectionReference<Map<String, dynamic>> _events;

  static const maxQueue = 200;

  CollectionReference<Map<String, dynamic>> _queue(String eventId) =>
      _events.doc(eventId).collection(FirestorePaths.waitlist);

  Stream<bool> watchIsWaiting(String eventId, String userId) =>
      _queue(eventId).doc(userId).snapshots().map((s) => s.exists);

  Stream<int> watchLength(String eventId) =>
      _queue(eventId).limit(maxQueue).snapshots().map((s) => s.size);

  /// Exactly the field set the rules accept; the position in the queue is the
  /// server `createdAt`, which nobody can edit afterwards.
  Future<void> join(String eventId, AppUser user) =>
      _queue(eventId).doc(user.id).set({
        'userId': user.id,
        'userName': user.name,
        'createdAt': FieldValue.serverTimestamp(),
      });

  Future<void> leave(String eventId, String userId) =>
      _queue(eventId).doc(userId).delete();
}
