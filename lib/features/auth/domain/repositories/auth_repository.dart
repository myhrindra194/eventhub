import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/auth/domain/entities/app_user.dart';
import 'package:eventhub/features/auth/domain/entities/auth_session.dart';

/// Contract for authentication + profile persistence.
/// Implementations must never throw; every failure is a `Result.err`.
///
/// One account, two spaces (the Eventbrite / Airbnb model): every account
/// starts as a participant, and turns the organizer space on later with
/// [becomeOrganizer]. Nobody picks a role at sign-up.
abstract interface class AuthRepository {
  /// Emits on every auth or profile change (including email verification).
  /// Never completes.
  Stream<AuthSession> watchSession();

  AsyncResult<AppUser> signIn({
    required String email,
    required String password,
  });

  /// Google account. A first sign-in has no profile yet: the session then
  /// becomes [ProfileMissing] and the router asks for a name.
  AsyncResult<void> signInWithGoogle();

  /// Creates the account and its participant profile, signs in and sends
  /// the verification email (a failure to send never fails the sign-up; the
  /// user can resend).
  AsyncResult<AppUser> signUp({
    required String name,
    required String email,
    required String password,
  });

  /// Creates the participant profile of an already-authenticated account
  /// (recovery path for [ProfileMissing], and first Google sign-in).
  AsyncResult<AppUser> completeProfile({required String name});

  /// Turns the organizer space on: verified email required, one way. Creates
  /// the public organizer page in the same batch.
  AsyncResult<AppUser> becomeOrganizer({String bio = ''});

  /// Updates the presentation fields of the signed-in user's profile (and of
  /// their public organizer page).
  ///
  /// Names already denormalised on past reservations are left untouched —
  /// a ticket keeps the name it was issued under.
  /// [bio] is left untouched when `null`; an empty string clears it.
  AsyncResult<AppUser> updateProfile({required String name, String? bio});

  AsyncResult<void> sendPasswordReset({required String email});

  /// Sends (again) the verification link to the signed-in user's address.
  AsyncResult<void> sendEmailVerification();

  /// Reloads the account and, when the address is now verified, refreshes
  /// the ID token so the rules see `email_verified == true` immediately.
  /// Returns the verification status.
  AsyncResult<bool> refreshEmailVerification();

  /// Changes the password of the currently signed-in account.
  ///
  /// [currentPassword] is not decoration: the provider requires a recent
  /// login for this operation, and re-authenticating with it turns an
  /// unactionable "requires-recent-login" into a plain "wrong password" the
  /// user can actually fix. It is also the only thing standing between an
  /// unlocked phone and a stolen account.
  AsyncResult<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Fires when a password-reset link opens the app. Firebase completes the
  /// reset on its own hosted page, so this stream stays silent; it is kept
  /// for providers that hand the reset back to the app.
  Stream<void> get passwordRecoveries;

  /// Sets a new password on the signed-in account without the current one.
  AsyncResult<void> setNewPassword(String newPassword);

  /// Whether the signed-in account has a password credential (otherwise it
  /// is a Google account). Decides how [deleteAccount] re-authenticates.
  bool get usesPasswordSignIn;

  /// Re-authenticates ([password] for a password account, Google otherwise),
  /// then deletes the account: upcoming seats released, history anonymised,
  /// personal data removed, the Authentication user deleted, signed out.
  /// Refused while an upcoming event of the account has participants.
  AsyncResult<void> deleteAccount({String? password});

  AsyncResult<void> signOut();
}
