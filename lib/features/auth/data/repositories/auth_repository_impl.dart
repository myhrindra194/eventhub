import 'dart:async';

import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/errors/failure_exception.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/core/utils/app_logger.dart';
import 'package:eventhub/features/auth/data/datasources/account_functions_data_source.dart';
import 'package:eventhub/features/auth/data/datasources/firebase_auth_data_source.dart';
import 'package:eventhub/features/auth/data/datasources/user_remote_data_source.dart';
import 'package:eventhub/features/auth/data/dtos/user_dto.dart';
import 'package:eventhub/features/auth/domain/entities/app_user.dart';
import 'package:eventhub/features/auth/domain/entities/auth_session.dart';
import 'package:eventhub/features/auth/domain/entities/user_role.dart';
import 'package:eventhub/features/auth/domain/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:rxdart/rxdart.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required FirebaseAuthDataSource authDataSource,
    required UserRemoteDataSource userDataSource,
    required AccountFunctionsDataSource accountFunctions,
    required Duration profileGracePeriod,
    required String googleServerClientId,
  }) : _auth = authDataSource,
       _users = userDataSource,
       _account = accountFunctions,
       _profileGracePeriod = profileGracePeriod,
       _googleServerClientId = googleServerClientId;

  final FirebaseAuthDataSource _auth;
  final UserRemoteDataSource _users;
  final AccountFunctionsDataSource _account;
  final Duration _profileGracePeriod;
  final String _googleServerClientId;

  /// Users whose role claim has already been checked this process.
  final _claimChecked = <String>{};

  @override
  Stream<AuthSession> watchSession() {
    // `userChanges` (not `authStateChanges`) so a reload after email
    // verification reaches the UI. It also fires on token refreshes, which
    // change nothing the session exposes: filtered out by `distinct`.
    // switchMap: a Firestore snapshot stream never completes, so the previous
    // profile subscription must be cancelled when the user changes.
    return _auth
        .userChanges()
        .distinct(
          (a, b) => a?.uid == b?.uid && a?.emailVerified == b?.emailVerified,
        )
        .switchMap<AuthSession>((user) {
          if (user == null) return Stream.value(const SignedOut());
          return _sessionFor(user);
        });
  }

  Stream<AuthSession> _sessionFor(User user) {
    return _users.watch(user.uid).switchMap<AuthSession>((dto) {
      if (dto != null) {
        _ensureRoleClaimOnce(user.uid, dto.role);
        return Stream.value(
          SignedIn(
            dto.toDomain(user.uid).copyWith(emailVerified: user.emailVerified),
          ),
        );
      }
      // Right after sign-up the auth user exists before the profile document
      // is written. Tolerate that window; if the profile still has not shown
      // up after the grace period, surface `ProfileMissing`.
      return TimerStream(
        ProfileMissing(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName,
        ),
        _profileGracePeriod,
      );
    });
  }

  void _ensureRoleClaimOnce(String uid, UserRole role) {
    if (!_claimChecked.add(uid)) return;
    unawaited(
      _auth.ensureRoleClaim(role.name).catchError((Object error) {
        AppLogger.warning('Role claim check failed', error: error);
      }),
    );
  }

  @override
  AsyncResult<AppUser> signIn({
    required String email,
    required String password,
  }) {
    return guard(() async {
      final user = await _auth.signIn(email: email, password: password);
      final dto = await _users.get(user.uid);
      if (dto == null) {
        throw const FailureException(
          AuthFailure(
            code: AuthFailureCode.profileMissing,
            message: 'Profil introuvable. Veuillez compléter votre profil.',
          ),
        );
      }
      return dto.toDomain(user.uid).copyWith(emailVerified: user.emailVerified);
    });
  }

  @override
  AsyncResult<void> signInWithGoogle() => guard(
    () => _auth.signInWithGoogle(serverClientId: _googleServerClientId),
  );

  @override
  AsyncResult<AppUser> signUp({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) {
    return guard(() async {
      final user = await _auth.signUp(email: email, password: password);
      final profile = await _createProfile(user, name: name, role: role);
      try {
        await _auth.sendEmailVerification();
      } on Object catch (error) {
        // The account exists: a mail hiccup must not turn a successful
        // sign-up into an error. The banner offers to resend.
        AppLogger.warning('Verification email not sent', error: error);
      }
      return profile;
    });
  }

  @override
  AsyncResult<AppUser> completeProfile({
    required String name,
    required UserRole role,
  }) {
    return guard(() async {
      final user = _auth.currentUser;
      if (user == null) throw const FailureException(AuthFailure.notSignedIn());
      return _createProfile(user, name: name, role: role);
    });
  }

  Future<AppUser> _createProfile(
    User user, {
    required String name,
    required UserRole role,
  }) async {
    final profile = AppUser(
      id: user.uid,
      name: name.trim(),
      email: user.email ?? '',
      role: role,
      emailVerified: user.emailVerified,
    );
    await _users.create(user.uid, UserDto.fromDomain(profile));
    return profile;
  }

  @override
  AsyncResult<AppUser> updateProfile({required String name}) {
    return guard(() async {
      final user = _auth.currentUser;
      if (user == null) throw const FailureException(AuthFailure.notSignedIn());
      await _users.updateName(user.uid, name.trim());
      // Read back rather than rebuilding locally: the document is the source
      // of truth, and the session stream will emit the same value anyway.
      final dto = await _users.get(user.uid);
      if (dto == null) {
        throw const FailureException(
          AuthFailure(
            code: AuthFailureCode.profileMissing,
            message: 'Profil introuvable. Veuillez compléter votre profil.',
          ),
        );
      }
      return dto.toDomain(user.uid).copyWith(emailVerified: user.emailVerified);
    });
  }

  @override
  AsyncResult<void> sendPasswordReset({required String email}) =>
      guard(() => _auth.sendPasswordReset(email));

  @override
  AsyncResult<void> sendEmailVerification() =>
      guard(_auth.sendEmailVerification);

  @override
  AsyncResult<bool> refreshEmailVerification() =>
      guard(_auth.refreshEmailVerification);

  @override
  AsyncResult<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return guard(
      () => _auth.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      ),
    );
  }

  @override
  bool get usesPasswordSignIn => _auth.usesPasswordSignIn;

  @override
  AsyncResult<void> deleteAccount({String? password}) {
    return guard(() async {
      await _auth.reauthenticate(
        password: password,
        serverClientId: _googleServerClientId,
      );
      await _account.deleteAccount();
      // The Auth user no longer exists server-side; drop the local session.
      await _auth.signOut();
    });
  }

  @override
  AsyncResult<void> signOut() => guard(_auth.signOut);
}
