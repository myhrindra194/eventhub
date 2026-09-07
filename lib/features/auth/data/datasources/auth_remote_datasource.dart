import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthRemoteDataSource {
  final FirebaseAuth _firebaseAuth;

  AuthRemoteDataSource({FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  Future<UserCredential> register({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-creation-failed',
        message: 'Impossible de créer le compte utilisateur.',
      );
    }

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'name': name,
      'email': email,
      'role': role,
    });

    return credential;
  }

  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    return await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> logout() async {
    await _firebaseAuth.signOut();
  }

  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }
}
