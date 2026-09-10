import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

import '../models/user_model.dart';

class AuthRemoteDataSource {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  AuthRemoteDataSource({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  Future<UserModel> register({
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

    await _firestore.collection('users').doc(user.uid).set({
      'name': name,
      'email': email,
      'role': role,
    });

    return UserModel.fromFirebase(
      user,
      profile: {'name': name, 'email': email, 'role': role},
    );
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-creation-failed',
        message: 'Impossible de récupérer l’utilisateur connecté.',
      );
    }

    return _toModel(user);
  }

  Future<UserModel?> loginWithGoogle() async {
    final UserCredential credential;

    if (kIsWeb) {
      credential = await _firebaseAuth.signInWithPopup(GoogleAuthProvider());
    } else {
      final googleUser = await _googleSignIn.authenticate();
      final googleAuth = googleUser.authentication;
      final authCredential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      credential = await _firebaseAuth.signInWithCredential(authCredential);
    }

    final user = credential.user;
    if (user == null) return null;

    await _ensureProfile(user);
    return _toModel(user);
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  Future<void> logout() async {
    if (!kIsWeb) await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }

  Stream<UserModel?> authStateChanges() {
    return _firebaseAuth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      return _toModel(user);
    });
  }

  Future<UserModel> _toModel(User user) async {
    final snapshot = await _firestore.collection('users').doc(user.uid).get();
    return UserModel.fromFirebase(user, profile: snapshot.data());
  }

  Future<void> _ensureProfile(User user) async {
    final reference = _firestore.collection('users').doc(user.uid);
    final snapshot = await reference.get();
    if (snapshot.exists) return;

    await reference.set({
      'name': user.displayName ?? '',
      'email': user.email ?? '',
      'role': 'participant',
    });
  }
}
