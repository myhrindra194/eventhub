import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';

/// Mock Firebase Auth prêt à l'emploi pour les tests.
///
/// Re-export pratique : `MockFirebaseAuth` signé avec `MockUser` (voir
/// package `firebase_auth_mocks`). À consommer pour injecter une session
/// factice dans `ReservationRemoteDataSourceImpl` et les providers Riverpod.
FirebaseAuth buildMockFirebaseAuth({
  String uid = 'user-1',
  String? email = 'user@example.com',
  String? displayName = 'Event User',
}) {
  final user = MockUser(
    isAnonymous: false,
    uid: uid,
    email: email,
    displayName: displayName,
  );
  // signedIn: true rend `currentUser` non-null (état connecté par défaut).
  return MockFirebaseAuth(signedIn: true, mockUser: user);
}

/// Retourne un `MockFirebaseAuth` déconnecté (`currentUser == null`).
FirebaseAuth buildMockFirebaseAuthSignedOut() {
  return MockFirebaseAuth(signedIn: false);
}
