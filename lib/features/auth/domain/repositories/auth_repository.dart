import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/auth/domain/entities/app_user.dart';
import 'package:eventhub/features/auth/domain/entities/auth_session.dart';
import 'package:eventhub/features/auth/domain/entities/user_role.dart';

/// Contract for authentication + profile persistence.
/// Implementations must never throw; every failure is a `Result.err`.
abstract interface class AuthRepository {
  /// Emits on every auth or profile change. Never completes.
  Stream<AuthSession> watchSession();

  AsyncResult<AppUser> signIn({
    required String email,
    required String password,
  });

  AsyncResult<AppUser> signUp({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  });

  /// Creates the Firestore profile for an already-authenticated account
  /// (recovery path for [ProfileMissing]).
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
  AsyncResult<AppUser> updateProfile({required String name});

  AsyncResult<void> sendPasswordReset({required String email});

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

  AsyncResult<void> signOut();
}
