import 'dart:async';

import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/errors/failure_exception.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/auth/data/datasources/account_remote_data_source.dart';
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
    required AccountRemoteDataSource accountDataSource,
    required Duration profileGracePeriod,
    required DateTime Function() clock,
  }) : _auth = authDataSource,
       _users = userDataSource,
       _account = accountDataSource,
       _profileGracePeriod = profileGracePeriod,
       _clock = clock;

  final FirebaseAuthDataSource _auth;
  final UserRemoteDataSource _users;
  final AccountRemoteDataSource _account;
  final Duration _profileGracePeriod;
  final DateTime Function() _clock;

  static const _suspended = AuthFailure(
    code: AuthFailureCode.userDisabled,
    message: 'Ce compte est suspendu par la modération.',
  );

  static const _profileMissing = AuthFailure(
    code: AuthFailureCode.profileMissing,
    message: 'Profil introuvable. Veuillez compléter votre profil.',
  );

  @override
  Stream<AuthSession> watchSession() {
    // Auth emits on every token refresh; only a change of account or of
    // email verification changes the session. switchMap: the profile stream
    // never completes, so the previous one must be cancelled when the
    // account changes (and before its listener is refused on sign-out).
    return _auth
        .userChanges()
        .distinct((a, b) => _sessionKey(a) == _sessionKey(b))
        .switchMap<AuthSession>((user) {
          if (user == null) return Stream.value(const SignedOut());
          return _profileSession(user);
        });
  }

  static String? _sessionKey(User? user) =>
      user == null ? null : '${user.uid}|${user.emailVerified}';

  Stream<AuthSession> _profileSession(User user) {
    return Rx.combineLatest2(
      _users.watch(user.uid),
      _users.watchIsAdmin(user.uid).startWith(false),
      (UserDto? dto, bool admin) => (dto, admin),
    ).switchMap<AuthSession>((pair) {
      final (dto, admin) = pair;
      if (dto != null && dto.suspended) {
        // Moderation suspended the account while it was signed in.
        unawaited(_auth.signOut());
        return Stream.value(const SignedOut());
      }
      if (dto != null) {
        return Stream.value(SignedIn(_toUser(user, dto, isAdmin: admin)));
      }
      // A password sign-up writes its profile right after the account; a
      // first Google sign-in has none yet. Give the document a moment to
      // show up, then ask for a name.
      return TimerStream(
        ProfileMissing(
          uid: user.uid,
          email: user.email ?? '',
          displayName: _displayName(user),
        ),
        _profileGracePeriod,
      );
    });
  }

  static AppUser _toUser(User user, UserDto dto, {bool isAdmin = false}) => dto
      .toDomain(user.uid)
      .copyWith(emailVerified: user.emailVerified, isAdmin: isAdmin);

  static String? _displayName(User user) {
    final name = user.displayName?.trim();
    return (name == null || name.isEmpty) ? null : name;
  }

  @override
  Stream<void> get passwordRecoveries => const Stream.empty();

  @override
  AsyncResult<AppUser> signIn({
    required String email,
    required String password,
  }) {
    return guard(() async {
      final user = await _auth.signIn(email: email, password: password);
      final dto = await _users.get(user.uid);
      if (dto == null) throw const FailureException(_profileMissing);
      if (dto.suspended) {
        await _auth.signOut();
        throw const FailureException(_suspended);
      }
      return _toUser(user, dto);
    });
  }

  @override
  AsyncResult<void> signInWithGoogle() => guard(_auth.signInWithGoogle);

  @override
  AsyncResult<AppUser> signUp({
    required String name,
    required String email,
    required String password,
  }) {
    return guard(() async {
      final trimmed = name.trim();
      final user = await _auth.signUp(
        email: email,
        password: password,
        name: trimmed,
      );
      final address = user.email ?? email.trim();
      await _users.create(user.uid, name: trimmed, email: address);
      // Never fails the sign-up: the banner offers to resend.
      await _auth.sendEmailVerification().catchError((_) {});
      return AppUser(
        id: user.uid,
        name: trimmed,
        email: address,
        role: UserRole.participant,
        emailVerified: user.emailVerified,
      );
    });
  }

  @override
  AsyncResult<AppUser> completeProfile({required String name}) {
    return guard(() async {
      final user = _auth.currentUser;
      if (user == null) throw const FailureException(AuthFailure.notSignedIn());
      final trimmed = name.trim();
      final email = user.email ?? '';
      await _users.create(user.uid, name: trimmed, email: email);
      return AppUser(
        id: user.uid,
        name: trimmed,
        email: email,
        role: UserRole.participant,
        emailVerified: user.emailVerified,
      );
    });
  }

  @override
  AsyncResult<AppUser> becomeOrganizer({String bio = ''}) {
    return guard(() async {
      final user = _auth.currentUser;
      if (user == null) throw const FailureException(AuthFailure.notSignedIn());
      // The rules read `email_verified` from the token: make it current.
      if (!await _auth.refreshEmailVerification()) {
        throw const FailureException(
          BusinessRuleFailure(
            rule: BusinessRule.emailNotVerified,
            message:
                'Confirmez votre adresse email pour ouvrir votre espace '
                'organisateur.',
          ),
        );
      }
      final dto = await _users.get(user.uid);
      if (dto == null) throw const FailureException(_profileMissing);
      if (dto.role == UserRole.organizer) return _toUser(user, dto);
      await _users.becomeOrganizer(
        user.uid,
        name: dto.name,
        email: user.email ?? dto.email,
        bio: bio.trim(),
      );
      return _toUser(
        user,
        dto.copyWith(role: UserRole.organizer, bio: bio.trim()),
      ).copyWith(emailVerified: true);
    });
  }

  @override
  AsyncResult<AppUser> updateProfile({required String name, String? bio}) {
    return guard(() async {
      final user = _auth.currentUser;
      if (user == null) throw const FailureException(AuthFailure.notSignedIn());
      final current = await _users.get(user.uid);
      if (current == null) throw const FailureException(_profileMissing);
      final trimmedBio = bio?.trim();
      await _users.updateProfile(
        user.uid,
        name: name.trim(),
        bio: trimmedBio,
        isOrganizer: current.role == UserRole.organizer,
      );
      return _toUser(
        user,
        current.copyWith(
          name: name.trim(),
          bio: trimmedBio == null
              ? current.bio
              : (trimmedBio.isEmpty ? null : trimmedBio),
        ),
      );
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
  AsyncResult<void> setNewPassword(String newPassword) =>
      guard(() => _auth.setNewPassword(newPassword));

  @override
  bool get usesPasswordSignIn => _auth.usesPasswordSignIn;

  @override
  AsyncResult<void> deleteAccount({String? password}) {
    return guard(() async {
      final user = _auth.currentUser;
      if (user == null) throw const FailureException(AuthFailure.notSignedIn());
      // First: a wrong password must stop everything before any data moves.
      await _auth.reauthenticate(password: password);
      final dto = await _users.get(user.uid);
      if (dto != null) {
        await _account.deleteAccountData(
          user.uid,
          email: user.email ?? dto.email,
          isOrganizer: dto.role == UserRole.organizer,
          now: _clock(),
        );
      }
      await _auth.deleteUser();
      await _auth.signOut();
    });
  }

  @override
  AsyncResult<void> signOut() => guard(_auth.signOut);
}
