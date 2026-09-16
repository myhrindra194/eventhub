import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventhub/core/firebase/firebase_providers.dart';
import 'package:eventhub/core/firebase/firestore_paths.dart';
import 'package:eventhub/features/auth/data/dtos/user_dto.dart';
import 'package:eventhub/features/auth/domain/entities/user_role.dart';

/// `users/{uid}` (propriétaire uniquement) et la page publique
/// `organizers/{uid}` qu’il alimente, plus le marqueur `admins/{uid}`.
class UserRemoteDataSource {
  const UserRemoteDataSource(this._db);

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _user(String uid) =>
      _db.collection(Collections.users).doc(uid);

  /// Crée le profil avec le rôle choisi à l'inscription.
  ///
  /// Un organisateur naît avec sa page publique vide, dans le même batch :
  /// les règles refusent un rôle organisateur sans elle. `intendedRole` garde
  /// la réponse brute du formulaire, utile pour réparer un compte dont
  /// l'écriture aurait été interrompue.
  Future<void> create(
    String uid, {
    required String name,
    required String email,
    UserRole intendedRole = UserRole.participant,
  }) async {
    final batch = _db.batch()
      ..set(_user(uid), {
        'name': name,
        'email': email,
        'role': intendedRole.name,
        'intendedRole': intendedRole.name,
        'createdAt': FieldValue.serverTimestamp(),
      });
    if (intendedRole == UserRole.organizer) {
      batch.set(_organizerPage(uid), _emptyPage(name, ''));
    }
    await batch.commit();
  }

  DocumentReference<Map<String, dynamic>> _organizerPage(String uid) =>
      _db.collection(Collections.organizers).doc(uid);

  static Map<String, Object?> _emptyPage(String name, String bio) => {
    'name': name,
    'bio': bio,
    'memberSince': FieldValue.serverTimestamp(),
    'followerCount': 0,
    'eventCount': 0,
    'ratingSum': 0,
    'ratingCount': 0,
  };

  /// L'entrée qui permet de retrouver un organisateur par son adresse (pour
  /// l'inviter à co-organiser). Les règles la réservent aux adresses
  /// vérifiées : elle est donc écrite à la confirmation, pas à l'inscription.
  /// Idempotente — réécrire la même valeur est sans effet.
  Future<void> registerOrganizerEmail(String uid, String email) => _db
      .collection(Collections.organizerEmails)
      .doc(DocIds.emailKey(email))
      .set({'uid': uid});

  /// Le nom, la présentation et les photos avancent ensemble sur le profil
  /// privé et, pour un organisateur, sur la page publique — les règles
  /// exigent que les deux disent la même chose.
  ///
  /// [updatePhotos] distingue « ne pas toucher aux photos » de « retirer la
  /// photo » : sans ce drapeau, un `null` voudrait dire les deux à la fois.
  Future<void> updateProfile(
    String uid, {
    required String name,
    required bool isOrganizer,
    String? bio,
    String? photoUrl,
    String? coverUrl,
    bool updatePhotos = false,
  }) async {
    final batch = _db.batch()
      ..update(_user(uid), {
        'name': name,
        if (bio != null) 'bio': bio.isEmpty ? null : bio,
        if (updatePhotos) ...{'photoUrl': photoUrl, 'coverUrl': coverUrl},
        'updatedAt': FieldValue.serverTimestamp(),
      });
    if (isOrganizer) {
      batch.update(_db.collection(Collections.organizers).doc(uid), {
        'name': name,
        'bio': ?bio,
        // La couverture reste privée : la page publique d'un organisateur
        // montre son visage, pas le décor de son profil.
        if (updatePhotos) 'photoUrl': photoUrl,
      });
    }
    await batch.commit();
  }

  Future<UserDto?> get(String uid) async {
    final snapshot = await _user(uid).get();
    final data = snapshot.data();
    return data == null ? null : UserDto.fromJson(data);
  }

  Stream<UserDto?> watch(String uid) => _user(uid).snapshots().map(
    (s) => s.data() == null ? null : UserDto.fromJson(s.data()!),
  );

  /// `admins/{uid}` existe : les règles n’autorisent chacun à poser la
  /// question que sur lui-même.
  Stream<bool> watchIsAdmin(String uid) => _db
      .collection(Collections.admins)
      .doc(uid)
      .snapshots()
      .map((s) => s.exists)
      .resilient('admin-marker');
}
