import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventhub/core/firebase/firebase_providers.dart';
import 'package:eventhub/core/firebase/firestore_paths.dart';

/// `users/{uid}/favorites/{eventId}` `{eventId, createdAt}` — owner only.
///
/// The rules allow `create` and `delete` but never `update`, so a `set` over
/// an existing favorite is refused: [add] reads before writing.
class FavoritesRemoteDataSource {
  const FavoritesRemoteDataSource(this._db);

  final FirebaseFirestore _db;

  /// Generous but bounded: a listener re-reads its whole result after a
  /// reconnection.
  static const maxFavorites = 500;

  CollectionReference<Map<String, dynamic>> _favorites(String uid) => _db
      .collection(Collections.users)
      .doc(uid)
      .collection(Collections.favorites);

  /// Event ids, most recently starred first. The document id *is* the event
  /// id.
  Stream<List<String>> watchIds(String uid) => _favorites(uid)
      .orderBy('createdAt', descending: true)
      .limit(maxFavorites)
      .snapshots()
      .map((s) => List<String>.unmodifiable([for (final d in s.docs) d.id]))
      .resilient('favorites');

  /// Idempotent, like the toggle expects: starring twice (two taps racing,
  /// another device) is not an error — an existing favorite is left as is.
  Future<void> add(String uid, String eventId) async {
    final ref = _favorites(uid).doc(eventId);
    if ((await ref.get()).exists) return;
    await ref.set({
      'eventId': eventId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Deleting a missing document succeeds: already idempotent.
  Future<void> remove(String uid, String eventId) =>
      _favorites(uid).doc(eventId).delete();
}
