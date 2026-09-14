import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Thin wrapper over [FirebaseAuth] and Google Sign-In; throws SDK exceptions
/// untouched (or as [FirebaseAuthException]) so the repository can map them
/// with `ErrorMapper`.
class FirebaseAuthDataSource {
  const FirebaseAuthDataSource(this._auth);

  final FirebaseAuth _auth;

  /// `GoogleSignIn.initialize` must run exactly once per process.
  static Future<void>? _googleInit;

  /// Fires on sign-in/out **and** on user updates (reload after email
  /// verification, profile changes, token refresh).
  Stream<User?> userChanges() => _auth.userChanges();

  User? get currentUser => _auth.currentUser;

  /// Whether the ID token carries the `admin` claim. Uses the cached token
  /// (works offline); a newly granted role shows after the next refresh.
  Future<bool> hasAdminClaim(User user) async {
    try {
      final token = await user.getIdTokenResult();
      return token.claims?['admin'] == true;
    } on Object {
      return false;
    }
  }

  bool get usesPasswordSignIn =>
      _auth.currentUser?.providerData.any(
        (p) => p.providerId == EmailAuthProvider.PROVIDER_ID,
      ) ??
      false;

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

  /// Web: Firebase popup (no plugin configuration needed). Mobile: native
  /// Google account picker, then a Firebase credential from its ID token.
  Future<User> signInWithGoogle({required String serverClientId}) async {
    if (kIsWeb) {
      final credential = await _auth.signInWithPopup(GoogleAuthProvider());
      return _requireUser(credential.user);
    }
    final credential = await _auth.signInWithCredential(
      await _googleCredential(serverClientId),
    );
    return _requireUser(credential.user);
  }

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  Future<void> sendEmailVerification() =>
      _requireUser(_auth.currentUser).sendEmailVerification();

  Future<bool> refreshEmailVerification() async {
    await _requireUser(_auth.currentUser).reload();
    final fresh = _requireUser(_auth.currentUser);
    // The claim lives in the ID token: without a forced refresh the rules
    // would keep seeing `email_verified: false` for up to an hour.
    if (fresh.emailVerified) await fresh.getIdToken(true);
    return fresh.emailVerified;
  }

  /// Waits for the `role` custom claim set by the `setRoleClaim` Cloud
  /// Function (a few seconds after the profile is created) and refreshes the
  /// token once it is there. Gives up silently: the rules fall back to the
  /// profile document.
  Future<void> ensureRoleClaim(String role) async {
    for (var attempt = 0; attempt < 4; attempt++) {
      final user = _auth.currentUser;
      if (user == null) return;
      final token = await user.getIdTokenResult(attempt > 0);
      if (token.claims?['role'] == role) return;
      await Future<void>.delayed(Duration(seconds: 2 + attempt * 3));
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _requireUser(_auth.currentUser);
    // Re-authenticate first: Firebase refuses `updatePassword` on a stale
    // session, and a failure here is reported as `wrong-password`, which the
    // UI can attach to the right field.
    await user.reauthenticateWithCredential(
      EmailAuthProvider.credential(
        email: _requireEmail(user),
        password: currentPassword,
      ),
    );
    await user.updatePassword(newPassword);
  }

  /// Proves the person holding the phone owns the account before an
  /// irreversible operation.
  Future<void> reauthenticate({
    String? password,
    required String serverClientId,
  }) async {
    final user = _requireUser(_auth.currentUser);
    if (usesPasswordSignIn) {
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(
          email: _requireEmail(user),
          password: password ?? '',
        ),
      );
      return;
    }
    if (kIsWeb) {
      await user.reauthenticateWithPopup(GoogleAuthProvider());
      return;
    }
    await user.reauthenticateWithCredential(
      await _googleCredential(serverClientId),
    );
  }

  Future<void> signOut() async {
    if (!kIsWeb && _googleInit != null) {
      // Otherwise the next "Continuer avec Google" silently reuses the
      // previous account instead of showing the picker.
      await GoogleSignIn.instance.signOut();
    }
    await _auth.signOut();
  }

  Future<AuthCredential> _googleCredential(String serverClientId) async {
    final google = GoogleSignIn.instance;
    await (_googleInit ??= google.initialize(
      serverClientId: serverClientId.isEmpty ? null : serverClientId,
    ));
    final GoogleSignInAccount account;
    try {
      account = await google.authenticate();
    } on GoogleSignInException catch (e) {
      throw FirebaseAuthException(
        code: e.code == GoogleSignInExceptionCode.canceled
            ? 'sign-in-cancelled'
            : 'google-sign-in-failed',
        message: e.description,
      );
    }
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw FirebaseAuthException(
        code: 'google-sign-in-failed',
        message: 'Google did not return an ID token',
      );
    }
    return GoogleAuthProvider.credential(idToken: idToken);
  }

  String _requireEmail(User user) {
    final email = user.email;
    if (email == null) {
      throw FirebaseAuthException(
        code: 'no-email',
        message: 'Account has no email credential',
      );
    }
    return email;
  }

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
