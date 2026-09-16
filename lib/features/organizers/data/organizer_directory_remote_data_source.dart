import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/errors/failure_exception.dart';
import 'package:eventhub/core/firebase/firebase_providers.dart';
import 'package:eventhub/core/firebase/firestore_paths.dart';
import 'package:eventhub/features/organizers/data/organizer_profile_dto.dart';
import 'package:eventhub/features/organizers/domain/organizer_profile.dart';

/// `organizers/{uid}` — public, lisible par tout compte connecté — et
/// `users/{uid}/following/{organizerId}`, privé à l'abonné.
///
/// Un abonnement, ce sont deux écritures que les règles n'acceptent
/// qu'ensemble : le document de l'abonné et `followerCount ± 1`, le compteur
/// étant prouvé par le document qui apparaît ou disparaît dans ce même commit
/// (`firebase/tests/social.rules.test.js`).
class OrganizerDirectoryRemoteDataSource {
  const OrganizerDirectoryRemoteDataSource(this._db);

  final FirebaseFirestore _db;

  /// Large, mais borné : après une reconnexion, un écouteur relit l'intégralité
  /// de son résultat, et les lectures sont le budget du plan Spark.
  static const maxFollowing = 500;

  DocumentReference<Map<String, dynamic>> _organizer(String id) =>
      _db.collection(Collections.organizers).doc(id);

  DocumentReference<Map<String, dynamic>> _follow(
    String uid,
    String organizerId,
  ) => _db
      .collection(Collections.users)
      .doc(uid)
      .collection(Collections.following)
      .doc(organizerId);

  Stream<OrganizerProfile?> watchProfile(String organizerId) =>
      _organizer(organizerId)
          .snapshots()
          .map((s) => s.data() == null ? null : profileFrom(s.id, s.data()!))
          .resilient('organizer-profile');

  /// Les identifiants des organisateurs, du plus récemment suivi au plus
  /// ancien. L'identifiant du document *est* celui de l'organisateur : un
  /// champ `organizerId` malformé ne peut donc induire personne en erreur.
  Stream<List<String>> watchFollowingIds(String uid) => _db
      .collection(Collections.users)
      .doc(uid)
      .collection(Collections.following)
      .orderBy('createdAt', descending: true)
      .limit(maxFollowing)
      .snapshots()
      .map((s) => List<String>.unmodifiable([for (final d in s.docs) d.id]))
      .resilient('following');

  /// Abonnement idempotent, dans une transaction : le test d'existence et les
  /// écritures sont validés ensemble, si bien que deux touchers concurrents —
  /// ou un second appareil — ne peuvent jamais compter l'abonné deux fois. La
  /// seconde tentative voit le document et ne fait rien.
  Future<void> follow(String uid, String organizerId) {
    final follow = _follow(uid, organizerId);
    final organizer = _organizer(organizerId);
    return _db.runTransaction<void>((tx) async {
      final existing = await tx.get(follow);
      if (existing.exists) return;
      final page = await tx.get(organizer);
      if (!page.exists) {
        throw const FailureException(
          NotFoundFailure(
            resource: Collections.organizers,
            message: 'Cet organisateur n’existe plus.',
          ),
        );
      }
      tx
        ..set(follow, {
          'organizerId': organizerId,
          'createdAt': FieldValue.serverTimestamp(),
        })
        ..update(organizer, {'followerCount': FieldValue.increment(1)});
    });
  }

  /// Désabonnement idempotent. Quand la page de l'organisateur a disparu — le
  /// compte a été supprimé — seul le document de l'abonné est retiré : les
  /// règles l'autorisent, et il ne reste aucun compteur à déplacer.
  Future<void> unfollow(String uid, String organizerId) {
    final follow = _follow(uid, organizerId);
    final organizer = _organizer(organizerId);
    return _db.runTransaction<void>((tx) async {
      final existing = await tx.get(follow);
      if (!existing.exists) return;
      final page = await tx.get(organizer);
      tx.delete(follow);
      if (page.exists) {
        tx.update(organizer, {'followerCount': FieldValue.increment(-1)});
      }
    });
  }

  static OrganizerProfile profileFrom(String id, Map<String, dynamic> data) =>
      OrganizerProfileDto.fromFirestore(id, data).toDomain();
}
