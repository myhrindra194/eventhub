import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventhub/core/firebase/firestore_paths.dart';
import 'package:eventhub/features/auth/data/dtos/user_dto.dart';

/// Firestore access for `users/{uid}`.
class UserRemoteDataSource {
  UserRemoteDataSource(FirebaseFirestore firestore)
    : _users = firestore.collection(FirestorePaths.users);

  final CollectionReference<Map<String, dynamic>> _users;

  Future<void> create(String uid, UserDto dto) {
    return _users.doc(uid).set({
      ...dto.toJson(),
      UserFields.createdAt: FieldValue.serverTimestamp(),
    });
  }

  /// Touches `name`, `bio` (when given) and `updatedAt` only — within the
  /// field set the security rules accept on update. An empty bio is stored
  /// as `null` rather than `""`.
  Future<void> updateProfile(String uid, {required String name, String? bio}) {
    return _users.doc(uid).update({
      UserFields.name: name,
      if (bio != null) UserFields.bio: bio.isEmpty ? null : bio,
      UserFields.updatedAt: FieldValue.serverTimestamp(),
    });
  }

  Future<UserDto?> get(String uid) async {
    final snapshot = await _users.doc(uid).get();
    return _fromSnapshot(snapshot);
  }

  Stream<UserDto?> watch(String uid) =>
      _users.doc(uid).snapshots().map(_fromSnapshot);

  UserDto? _fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    return data == null ? null : UserDto.fromJson(data);
  }
}
