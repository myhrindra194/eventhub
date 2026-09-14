import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/auth/domain/entities/app_user.dart';
import 'package:eventhub/features/auth/domain/entities/auth_session.dart';
import 'package:eventhub/features/auth/domain/entities/user_role.dart';

/// Contract for authentication + profile persistence.
/// Implementations must never throw; every failure is a `Result.err`.
abstract interface class AuthRepository {
  /// Emits on every auth or profile change (including email verification).
  /// Never completes.
  Stream<AuthSession> watchSession();

  AsyncResult<AppUser> signIn({
    required String email,
    required String password,
  });

  /// Google account. A first sign-in has no profile yet: the session then
  /// becomes [ProfileMissing] and the router asks for the role.
  AsyncResult<void> signInWithGoogle();

  /// Creates the account and sends the verification email (a failure to send
  /// never fails the sign-up; the user can resend).
  AsyncResult<AppUser> signUp({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  });

  /// Creates the Firestore profile for an already-authenticated account
  /// (recovery path for [ProfileMissing], and first Google sign-in).
  AsyncResult<AppUser> completeProfile({
    required String name,
    required UserRole role,
  });

  /// Updates the presentation fields of the signed-in user's profile.
  ///
  /// Only the display name moves: `email` and `role` are frozen by the
  /// security rules, so the contract does not even offer to change them.
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

  /// Whether the signed-in account has a password credential (otherwise it
  /// is a Google account). Decides how [deleteAccount] re-authenticates.
  bool get usesPasswordSignIn;

  /// Re-authenticates ([password] for a password account, Google otherwise),
  /// then deletes the account server-side (Cloud Function `deleteAccount`)
  /// and signs out.
  AsyncResult<void> deleteAccount({String? password});

  AsyncResult<void> signOut();
}
