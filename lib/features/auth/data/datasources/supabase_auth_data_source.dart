import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/errors/failure_exception.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin wrapper over Supabase Auth and native Google Sign-In. SDK exceptions
/// pass through untouched for `ErrorMapper`; a cancelled Google picker
/// becomes a [FailureException] the UI knows not to display.
class SupabaseAuthDataSource {
  const SupabaseAuthDataSource(this._auth, {required this.redirectUrl});

  final GoTrueClient _auth;

  /// Where confirmation and recovery links return (`AppConfig.authRedirectUrl`).
  final String redirectUrl;

  /// `GoogleSignIn.initialize` must run exactly once per process.
  static Future<void>? _googleInit;

  /// The current user, then every change: sign-in/out, token refresh, user
  /// update (confirmed email, new app_metadata such as the admin role).
  Stream<User?> userChanges() async* {
    yield _auth.currentUser;
    yield* _auth.onAuthStateChange.map((state) => state.session?.user);
  }

  /// A password-recovery link was opened: the app asks for a new password.
  Stream<void> get passwordRecoveries => _auth.onAuthStateChange
      .where((state) => state.event == AuthChangeEvent.passwordRecovery)
      .map((_) {});

  User? get currentUser => _auth.currentUser;

  /// `app_metadata.admin`, written by the database (`private.apply_admin`),
  /// never editable by the user. A new grant shows after the next token
  /// refresh; every admin action is re-checked server-side anyway.
  static bool isAdmin(User user) => user.appMetadata['admin'] == true;

  static bool isEmailVerified(User user) => user.emailConfirmedAt != null;

  bool get usesPasswordSignIn {
    final user = _auth.currentUser;
    if (user == null) return false;
    final providers = user.appMetadata['providers'];
    if (providers is List) return providers.contains('email');
    return user.appMetadata['provider'] == 'email';
  }

  Future<User> signIn({required String email, required String password}) async {
    final response = await _auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    return _requireUser(response.user);
  }

  /// Creates the account; Supabase sends the confirmation email. Name and
  /// role travel as metadata: the database creates the profile in the same
  /// transaction (`private.handle_new_auth_user`), because there is no
  /// session to write it with until the address is confirmed.
  Future<User> signUp({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    final response = await _auth.signUp(
      email: email.trim(),
      password: password,
      emailRedirectTo: redirectUrl,
      data: {'name': name, 'role': role},
    );
    final user = _requireUser(response.user);
    // An existing address comes back as an obfuscated user without
    // identities (anti-enumeration): say it plainly, as the form expects.
    if (user.identities != null && user.identities!.isEmpty) {
      throw const FailureException(
        AuthFailure(
          code: AuthFailureCode.emailAlreadyInUse,
          message: 'Un compte existe déjà avec cet email.',
        ),
      );
    }
    return user;
  }

  /// Web: OAuth redirect (the page reloads signed in). Mobile: native account
  /// picker, then its ID token exchanged for a Supabase session.
  Future<void> signInWithGoogle({required String serverClientId}) async {
    if (kIsWeb) {
      await _auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: Uri.base.origin,
      );
      return;
    }
    await _auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: await _googleIdToken(serverClientId),
    );
  }

  Future<void> sendPasswordReset(String email) =>
      _auth.resetPasswordForEmail(email.trim(), redirectTo: redirectUrl);

  Future<void> sendEmailVerification() async {
    final email = _requireUser(_auth.currentUser).email;
    if (email == null) return;
    await _auth.resend(
      type: OtpType.signup,
      email: email,
      emailRedirectTo: redirectUrl,
    );
  }

  Future<bool> refreshEmailVerification() async {
    await _auth.refreshSession();
    final response = await _auth.getUser();
    return response.user?.emailConfirmedAt != null;
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _requireUser(_auth.currentUser);
    // Signing in again proves the current password (a wrong one is reported
    // as invalid credentials, attachable to the right field) and makes the
    // session recent, which `secure_password_change` requires.
    await _auth.signInWithPassword(
      email: _requireEmail(user),
      password: currentPassword,
    );
    await _auth.updateUser(UserAttributes(password: newPassword));
  }

  /// After a recovery link: the link itself proved ownership of the address.
  Future<void> setNewPassword(String newPassword) =>
      _auth.updateUser(UserAttributes(password: newPassword));

  /// Proves the person holding the phone owns the account before an
  /// irreversible operation.
  Future<void> reauthenticate({
    String? password,
    required String serverClientId,
  }) async {
    final user = _requireUser(_auth.currentUser);
    if (usesPasswordSignIn) {
      await _auth.signInWithPassword(
        email: _requireEmail(user),
        password: password ?? '',
      );
      return;
    }
    // The web OAuth flow leaves the page: the live session stands in.
    if (kIsWeb) return;
    await _auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: await _googleIdToken(serverClientId),
    );
  }

  Future<void> signOut() async {
    if (!kIsWeb && _googleInit != null) {
      // Otherwise the next "Continuer avec Google" silently reuses the
      // previous account instead of showing the picker.
      await GoogleSignIn.instance.signOut();
    }
    // Local scope (the default): also works once the account no longer
    // exists server-side.
    await _auth.signOut();
  }

  Future<String> _googleIdToken(String serverClientId) async {
    final google = GoogleSignIn.instance;
    await (_googleInit ??= google.initialize(
      serverClientId: serverClientId.isEmpty ? null : serverClientId,
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
    return idToken;
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
