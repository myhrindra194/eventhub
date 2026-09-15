import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventhub/core/firebase/firebase_providers.dart';
import 'package:eventhub/core/firebase/firestore_paths.dart';
import 'package:eventhub/features/waitlist/domain/waitlist_repository.dart';

/// `events/{eventId}/waitlist/{userId}` {userId, createdAt, notifiedAt?}.
///
/// The document id is the uid: one entry per person without a query, and
/// the rules find "is this person waiting" with a single `exists()`. The
/// position is the server clock (`createdAt`), never a client value.
class WaitlistRemoteDataSource {
  const WaitlistRemoteDataSource(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _queue(String eventId) => _db
      .collection(Collections.events)
      .doc(eventId)
      .collection(Collections.waitlist);

  Stream<bool> watchIsWaiting(String eventId, String userId) => _queue(eventId)
      .doc(userId)
      .snapshots()
      .map((s) => s.exists)
      .distinct()
      .resilient('waitlist:mine:$eventId');

  /// A count aggregate would be exact, but the rules bound every list of a
  /// queue to 20 documents (the queue must not be scraped for uids), and
  /// that bound applies to aggregates too. The team's badge therefore reads
  /// the first 20 entries live and shows "20+" at the cap.
  Stream<int> watchLength(String eventId) => _queue(eventId)
      .limit(WaitlistRepository.queueLengthCap)
      .snapshots()
      .map((q) => q.size)
      .distinct()
      .resilient('waitlist:$eventId');

  /// Idempotent: a second tap must not turn into an update the rules refuse
  /// (and would reset nothing anyway — the position is kept).
  Future<void> join(String eventId, String userId) async {
    final entry = _queue(eventId).doc(userId);
    if ((await entry.get()).exists) return;
    await entry.set({
      'userId': userId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> leave(String eventId, String userId) =>
      _queue(eventId).doc(userId).delete();
}
