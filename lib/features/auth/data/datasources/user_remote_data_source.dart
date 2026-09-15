import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventhub/core/firebase/firebase_providers.dart';
import 'package:eventhub/core/firebase/firestore_paths.dart';
import 'package:eventhub/features/auth/data/dtos/user_dto.dart';
import 'package:eventhub/features/auth/domain/entities/user_role.dart';

/// `users/{uid}` (owner only) and the public `organizers/{uid}` page it
/// feeds, plus the `admins/{uid}` marker.
class UserRemoteDataSource {
  const UserRemoteDataSource(this._db);

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _user(String uid) =>
      _db.collection(Collections.users).doc(uid);

  /// Every account starts as a participant; the rules refuse anything else.
  Future<void> create(String uid, {required String name, required String email}) =>
      _user(uid).set({
        'name': name,
        'email': email,
        'role': UserRole.participant.name,
        'createdAt': FieldValue.serverTimestamp(),
      });

  /// Name and bio move together on the private profile and, for an
  /// organizer, on the public page (the rules require both to agree).
  Future<void> updateProfile(
    String uid, {
    required String name,
    required bool isOrganizer,
    String? bio,
  }) async {
    final batch = _db.batch()
      ..update(_user(uid), {
        'name': name,
        if (bio != null) 'bio': bio.isEmpty ? null : bio,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    if (isOrganizer) {
      batch.update(_db.collection(Collections.organizers).doc(uid), {
        'name': name,
        'bio': ?bio,
      });
    }
    await batch.commit();
  }

  /// Turns the organizer space on, in the one batch the rules accept: role,
  /// empty public page, and the e-mail lookup entry co-organizer invitations
  /// resolve.
  Future<void> becomeOrganizer(
    String uid, {
    required String name,
    required String email,
    required String bio,
  }) async {
    final batch = _db.batch()
      ..update(_user(uid), {
        'role': UserRole.organizer.name,
        'updatedAt': FieldValue.serverTimestamp(),
      })
      ..set(_db.collection(Collections.organizers).doc(uid), {
        'name': name,
        'bio': bio,
        'memberSince': FieldValue.serverTimestamp(),
        'followerCount': 0,
        'eventCount': 0,
        'ratingSum': 0,
        'ratingCount': 0,
      })
      ..set(
        _db.collection(Collections.organizerEmails).doc(DocIds.emailKey(email)),
        {'uid': uid},
      );
    await batch.commit();
  }

  Future<UserDto?> get(String uid) async {
    final snapshot = await _user(uid).get();
    final data = snapshot.data();
    return data == null ? null : UserDto.fromJson(data);
  }

  Stream<UserDto?> watch(String uid) => _user(uid)
      .snapshots()
      .map((s) => s.data() == null ? null : UserDto.fromJson(s.data()!));

  /// `admins/{uid}` exists: the rules let anyone ask about themself only.
  Stream<bool> watchIsAdmin(String uid) => _db
      .collection(Collections.admins)
      .doc(uid)
      .snapshots()
      .map((s) => s.exists)
      .resilient('admin-marker');
}
