import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/errors/failure_exception.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Fine enveloppe autour de Firebase Authentication et du Google Sign-In
/// natif. Les exceptions du SDK remontent intactes pour `ErrorMapper` ; un
/// sélecteur Google annulé devient une [FailureException] que l’UI sait ne
/// pas afficher.
class FirebaseAuthDataSource {
  FirebaseAuthDataSource(this._auth, {required this.googleServerClientId});

  final FirebaseAuth _auth;

  /// Identifiant client web OAuth, exigé par Google Sign-In sur Android.
  final String googleServerClientId;

  /// `GoogleSignIn.initialize` ne doit s’exécuter qu’une seule fois par
  /// processus.
  static Future<void>? _googleInit;

  /// Les e-mails (vérification, réinitialisation du mot de passe) dans la
  /// langue de l’application.
  static const _emailLanguage = 'fr';

  /// Connexion, déconnexion, changements de profil et de token — y compris
  /// une adresse vérifiée après [reload].
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

  /// Crée le compte ; Firebase le connecte dans la foulée.
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

  /// Web : popup Firebase. Mobile : sélecteur de compte natif, puis son ID
  /// token échangé contre un credential Firebase.
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

  /// Recharge le compte ; une fois l’adresse vérifiée, force un nouvel ID
  /// token pour que le claim `email_verified` que lisent les règles soit à
  /// jour.
  Future<bool> refreshEmailVerification() async {
    final user = _requireUser(_auth.currentUser);
    await user.reload();
    final fresh = _requireUser(_auth.currentUser);
    if (fresh.emailVerified) await fresh.getIdToken(true);
    return fresh.emailVerified;
  }

  /// Un ID token frais, pour qu’un claim qui vient de changer (une adresse
  /// vérifiée) parvienne jusqu’aux règles.
  Future<void> refreshToken() async {
    await _requireUser(_auth.currentUser).getIdToken(true);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _requireUser(_auth.currentUser);
    // Se réauthentifier prouve le mot de passe actuel (un mot de passe erroné
    // est remonté comme des identifiants invalides, rattachables au bon
    // champ) et rend la session récente, ce qu’exige un changement de mot de
    // passe.
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

  /// Prouve que la personne qui tient l’appareil est bien propriétaire du
  /// compte, avant une opération irréversible.
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

  /// Supprime l’utilisateur Authentication (la session doit être récente).
  Future<void> deleteUser() => _requireUser(_auth.currentUser).delete();

  Future<void> signOut() async {
    if (!kIsWeb && _googleInit != null) {
      // Sans cela, le prochain « Continuer avec Google » réutilise en
      // silence le compte précédent au lieu d’afficher le sélecteur.
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
