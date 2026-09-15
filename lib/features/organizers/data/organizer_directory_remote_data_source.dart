import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/errors/failure_exception.dart';
import 'package:eventhub/core/firebase/firebase_providers.dart';
import 'package:eventhub/core/firebase/firestore_paths.dart';
import 'package:eventhub/features/organizers/data/organizer_profile_dto.dart';
import 'package:eventhub/features/organizers/domain/organizer_profile.dart';

/// `organizers/{uid}` (public, read by any signed-in user) and
/// `users/{uid}/following/{organizerId}` (private to the follower).
///
/// A follow is two writes the rules accept only together: the follower's
/// document and `followerCount ± 1`, the counter proven by the document
/// appearing or disappearing in the same commit
/// (`firebase/tests/social.rules.test.js`).
class OrganizerDirectoryRemoteDataSource {
  const OrganizerDirectoryRemoteDataSource(this._db);

  final FirebaseFirestore _db;

  /// Generous but bounded: a listener re-reads its whole result after a
  /// reconnection.
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

  /// Organizer ids, most recently followed first. The document id *is* the
  /// organizer id, so a malformed `organizerId` field cannot mislead.
  Stream<List<String>> watchFollowingIds(String uid) => _db
      .collection(Collections.users)
      .doc(uid)
      .collection(Collections.following)
      .orderBy('createdAt', descending: true)
      .limit(maxFollowing)
      .snapshots()
      .map((s) => List<String>.unmodifiable([for (final d in s.docs) d.id]))
      .resilient('following');

  /// Idempotent follow, in a transaction: the existence check and the writes
  /// commit together, so two taps racing (or a second device) can never
  /// count a follower twice — the second attempt sees the document and does
  /// nothing.
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

  /// Idempotent unfollow. When the organizer page is gone (the account was
  /// deleted), only the follower's document is removed: the rules allow it,
  /// and there is no counter left to move.
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
