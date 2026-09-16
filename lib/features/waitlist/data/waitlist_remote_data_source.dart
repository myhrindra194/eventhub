import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventhub/core/firebase/firebase_providers.dart';
import 'package:eventhub/core/firebase/firestore_paths.dart';
import 'package:eventhub/features/waitlist/domain/waitlist_repository.dart';

/// `events/{eventId}/waitlist/{userId}` {userId, createdAt, notifiedAt?}.
///
/// L’id du document est l’uid : une entrée par personne sans requête, et les
/// règles répondent à « cette personne attend-elle ? » par un unique
/// `exists()`. La position est donnée par l’horloge du serveur
/// (`createdAt`), jamais par une valeur du client.
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

  /// Un agrégat `count` serait exact, mais les règles bornent toute liste
  /// d’une file à 20 documents (la file ne doit pas être moissonnée pour ses
  /// uid), et cette borne vaut aussi pour les agrégats. Le badge de l’équipe
  /// lit donc les 20 premières entrées en direct et affiche « 20+ » au
  /// plafond.
  Stream<int> watchLength(String eventId) => _queue(eventId)
      .limit(WaitlistRepository.queueLengthCap)
      .snapshots()
      .map((q) => q.size)
      .distinct()
      .resilient('waitlist:$eventId');

  /// Idempotent : un second appui ne doit pas se transformer en une mise à
  /// jour que les règles refusent (et qui ne réinitialiserait rien de toute
  /// façon — la position est conservée).
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
