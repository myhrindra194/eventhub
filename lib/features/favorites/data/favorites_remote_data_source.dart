import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventhub/core/firebase/firestore_paths.dart';

class FavoritesRemoteDataSource {
  FavoritesRemoteDataSource(FirebaseFirestore firestore)
    : _users = firestore.collection(FirestorePaths.users);

  final CollectionReference<Map<String, dynamic>> _users;

  /// Generous but bounded: a listener bills one read per document.
  static const maxFavorites = 500;

  CollectionReference<Map<String, dynamic>> _favorites(String uid) =>
      _users.doc(uid).collection(FirestorePaths.favorites);

  Stream<List<String>> watchIds(String uid) => _favorites(uid)
      .orderBy('createdAt', descending: true)
      .limit(maxFavorites)
      .snapshots()
      .map((s) => s.docs.map((d) => d.id).toList(growable: false));

  /// Exactly the field set the rules accept (`eventId`, server `createdAt`).
  Future<void> add(String uid, String eventId) => _favorites(uid)
      .doc(eventId)
      .set({'eventId': eventId, 'createdAt': FieldValue.serverTimestamp()});

  Future<void> remove(String uid, String eventId) =>
      _favorites(uid).doc(eventId).delete();
}
