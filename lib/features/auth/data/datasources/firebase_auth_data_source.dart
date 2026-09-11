import 'package:firebase_auth/firebase_auth.dart';

/// Thin wrapper over [FirebaseAuth]; throws SDK exceptions untouched so the
/// repository can map them with `ErrorMapper`.
class FirebaseAuthDataSource {
  const FirebaseAuthDataSource(this._auth);

  final FirebaseAuth _auth;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<User> signIn({required String email, required String password}) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return _requireUser(credential.user);
  }

  Future<User> signUp({required String email, required String password}) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return _requireUser(credential.user);
  }

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _requireUser(_auth.currentUser);
    final email = user.email;
    if (email == null) {
      throw FirebaseAuthException(
        code: 'no-email',
        message: 'Account has no email credential',
      );
    }
    // Re-authenticate first: Firebase refuses `updatePassword` on a stale
    // session, and a failure here is reported as `wrong-password`, which the
    // UI can attach to the right field.
    await user.reauthenticateWithCredential(
      EmailAuthProvider.credential(email: email, password: currentPassword),
    );
    await user.updatePassword(newPassword);
  }

  Future<void> signOut() => _auth.signOut();

  User _requireUser(User? user) {
    if (user == null) {
      throw FirebaseAuthException(
        code: 'null-user',
        message: 'Firebase returned no user',
      );
    }
    return user;
  }
}
