import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventhub/core/firebase/firestore_paths.dart';
import 'package:eventhub/features/organizers/domain/organizer_profile.dart';

/// Firestore access for `organizers/{id}` (read-only) and
/// `users/{uid}/following/{organizerId}`.
class OrganizerDirectoryRemoteDataSource {
  OrganizerDirectoryRemoteDataSource(FirebaseFirestore firestore)
    : _organizers = firestore.collection(FirestorePaths.organizers),
      _users = firestore.collection(FirestorePaths.users);

  final CollectionReference<Map<String, dynamic>> _organizers;
  final CollectionReference<Map<String, dynamic>> _users;

  /// Bounded like favourites: a listener bills one read per document.
  static const maxFollowing = 500;

  CollectionReference<Map<String, dynamic>> _following(String uid) =>
      _users.doc(uid).collection(FirestorePaths.following);

  Stream<OrganizerProfile?> watchProfile(String organizerId) =>
      _organizers.doc(organizerId).snapshots().map((s) {
        final data = s.data();
        return data == null ? null : profileFromFirestore(s.id, data);
      });

  Stream<List<String>> watchFollowingIds(String uid) => _following(uid)
      .orderBy('createdAt', descending: true)
      .limit(maxFollowing)
      .snapshots()
      .map((s) => s.docs.map((d) => d.id).toList(growable: false));

  /// Exactly the field set the rules accept.
  Future<void> follow(String uid, String organizerId) =>
      _following(uid).doc(organizerId).set({
        'organizerId': organizerId,
        'createdAt': FieldValue.serverTimestamp(),
      });

  Future<void> unfollow(String uid, String organizerId) =>
      _following(uid).doc(organizerId).delete();

  static OrganizerProfile profileFromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    int count(String key) => (data[key] as num?)?.toInt() ?? 0;
    return OrganizerProfile(
      id: id,
      name: data['name'] as String? ?? '',
      bio: data['bio'] as String? ?? '',
      // Counters are incremented by triggers; a negative value can only be
      // a transient artefact and is never shown.
      followerCount: math.max(0, count('followerCount')),
      eventCount: math.max(0, count('eventCount')),
      ratingSum: math.max(0, count('ratingSum')),
      ratingCount: math.max(0, count('ratingCount')),
      memberSince: switch (data['memberSince']) {
        final Timestamp t => t.toDate(),
        _ => null,
      },
    );
  }
}
