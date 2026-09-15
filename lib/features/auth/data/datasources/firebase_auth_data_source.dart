import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/errors/failure_exception.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Thin wrapper over Firebase Authentication and native Google Sign-In. SDK
/// exceptions pass through untouched for `ErrorMapper`; a cancelled Google
/// picker becomes a [FailureException] the UI knows not to display.
class FirebaseAuthDataSource {
  FirebaseAuthDataSource(this._auth, {required this.googleServerClientId});

  final FirebaseAuth _auth;

  /// OAuth web client id, required by Google Sign-In on Android.
  final String googleServerClientId;

  /// `GoogleSignIn.initialize` must run exactly once per process.
  static Future<void>? _googleInit;

  /// Emails (verification, password reset) in the app's language.
  static const _emailLanguage = 'fr';

  /// Sign-in, sign-out, profile and token changes — including a verified
  /// address after [reload].
  Stream<User?> userChanges() => _auth.userChanges();

  User? get currentUser => _auth.currentUser;

  bool get usesPasswordSignIn =>
      _auth.currentUser?.providerData.any(
        (info) => info.providerId == EmailAuthProvider.PROVIDER_ID,
      ) ??
      false;

  Future<User> signIn({required String email, required String password}) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return _requireUser(credential.user);
  }

  /// Creates the account; Firebase signs it in right away.
  Future<User> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = _requireUser(credential.user);
    await user.updateDisplayName(name);
    return user;
  }

  /// Web: Firebase popup. Mobile: native account picker, then its ID token
  /// exchanged for a Firebase credential.
  Future<void> signInWithGoogle() async {
    if (kIsWeb) {
      await _auth.signInWithPopup(GoogleAuthProvider());
      return;
    }
    await _auth.signInWithCredential(await _googleCredential());
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.setLanguageCode(_emailLanguage);
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> sendEmailVerification() async {
    final user = _requireUser(_auth.currentUser);
    if (user.emailVerified) return;
    await _auth.setLanguageCode(_emailLanguage);
    await user.sendEmailVerification();
  }

  /// Reloads the account; once verified, forces a new ID token so the
  /// `email_verified` claim the rules read is up to date.
  Future<bool> refreshEmailVerification() async {
    final user = _requireUser(_auth.currentUser);
    await user.reload();
    final fresh = _requireUser(_auth.currentUser);
    if (fresh.emailVerified) await fresh.getIdToken(true);
    return fresh.emailVerified;
  }

  /// A fresh ID token, so a claim that just changed (a verified address)
  /// reaches the rules.
  Future<void> refreshToken() async {
    await _requireUser(_auth.currentUser).getIdToken(true);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _requireUser(_auth.currentUser);
    // Re-authenticating proves the current password (a wrong one is reported
    // as invalid credentials, attachable to the right field) and makes the
    // session recent, which a password change requires.
    await user.reauthenticateWithCredential(
      EmailAuthProvider.credential(
        email: _requireEmail(user),
        password: currentPassword,
      ),
    );
    await user.updatePassword(newPassword);
  }

  Future<void> setNewPassword(String newPassword) =>
      _requireUser(_auth.currentUser).updatePassword(newPassword);

  /// Proves the person holding the device owns the account before an
  /// irreversible operation.
  Future<void> reauthenticate({String? password}) async {
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
    await user.reauthenticateWithCredential(await _googleCredential());
  }

  /// Deletes the Authentication user (the session must be recent).
  Future<void> deleteUser() => _requireUser(_auth.currentUser).delete();

  Future<void> signOut() async {
    if (!kIsWeb && _googleInit != null) {
      // Otherwise the next "Continuer avec Google" silently reuses the
      // previous account instead of showing the picker.
      await GoogleSignIn.instance.signOut();
    }
    await _auth.signOut();
  }

  Future<AuthCredential> _googleCredential() async {
    final google = GoogleSignIn.instance;
    await (_googleInit ??= google.initialize(
      serverClientId: googleServerClientId.isEmpty
          ? null
          : googleServerClientId,
    ));
    final GoogleSignInAccount account;
    try {
      account = await google.authenticate();
    } on GoogleSignInException catch (e) {
      throw FailureException(
        e.code == GoogleSignInExceptionCode.canceled
            ? const AuthFailure(
                code: AuthFailureCode.cancelled,
                message: 'Connexion annulée.',
              )
            : AuthFailure(
                code: AuthFailureCode.unknown,
                message: 'Connexion Google impossible.',
                cause: e,
              ),
      );
    }
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw const FailureException(
        AuthFailure(
          code: AuthFailureCode.unknown,
          message: 'Google n’a pas renvoyé d’identité.',
        ),
      );
    }
    return GoogleAuthProvider.credential(idToken: idToken);
  }

  String _requireEmail(User user) {
    final email = user.email;
    if (email == null) {
      throw const FailureException(
        AuthFailure(
          code: AuthFailureCode.unknown,
          message: 'Ce compte n’a pas d’adresse email.',
        ),
      );
    }
    return email;
  }

  User _requireUser(User? user) {
    if (user == null) throw const FailureException(AuthFailure.notSignedIn());
    return user;
  }
}
