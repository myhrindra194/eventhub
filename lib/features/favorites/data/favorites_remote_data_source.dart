import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventhub/core/firebase/firebase_providers.dart';
import 'package:eventhub/core/firebase/firestore_paths.dart';

/// `users/{uid}/favorites/{eventId}` `{eventId, createdAt}` — réservé au
/// propriétaire.
///
/// Les règles autorisent `create` et `delete`, jamais `update` : un `set`
/// par-dessus un favori existant est donc refusé, et [add] lit avant
/// d’écrire.
class FavoritesRemoteDataSource {
  const FavoritesRemoteDataSource(this._db);

  final FirebaseFirestore _db;

  /// Généreux mais borné : un listener relit tout son résultat après une
  /// reconnexion.
  static const maxFavorites = 500;

  CollectionReference<Map<String, dynamic>> _favorites(String uid) => _db
      .collection(Collections.users)
      .doc(uid)
      .collection(Collections.favorites);

  /// Identifiants d’événements, du favori le plus récent au plus ancien.
  /// L’id du document *est* l’id de l’événement.
  Stream<List<String>> watchIds(String uid) => _favorites(uid)
      .orderBy('createdAt', descending: true)
      .limit(maxFavorites)
      .snapshots()
      .map((s) => List<String>.unmodifiable([for (final d in s.docs) d.id]))
      .resilient('favorites');

  /// Idempotent, comme la bascule l’attend : mettre deux fois en favori
  /// (deux tapes en concurrence, un autre appareil) n’est pas une erreur —
  /// un favori existant est laissé tel quel.
  Future<void> add(String uid, String eventId) async {
    final ref = _favorites(uid).doc(eventId);
    if ((await ref.get()).exists) return;
    await ref.set({
      'eventId': eventId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Supprimer un document absent réussit : c’est déjà idempotent.
  Future<void> remove(String uid, String eventId) =>
      _favorites(uid).doc(eventId).delete();
}
