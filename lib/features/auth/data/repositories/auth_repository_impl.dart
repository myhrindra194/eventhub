import 'dart:async';

import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/errors/failure_exception.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/auth/data/datasources/account_remote_data_source.dart';
import 'package:eventhub/features/auth/data/datasources/supabase_auth_data_source.dart';
import 'package:eventhub/features/auth/data/datasources/user_remote_data_source.dart';
import 'package:eventhub/features/auth/data/dtos/user_dto.dart';
import 'package:eventhub/features/auth/domain/entities/app_user.dart';
import 'package:eventhub/features/auth/domain/entities/auth_session.dart';
import 'package:eventhub/features/auth/domain/entities/user_role.dart';
import 'package:eventhub/features/auth/domain/repositories/auth_repository.dart';
import 'package:rxdart/rxdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required SupabaseAuthDataSource authDataSource,
    required UserRemoteDataSource userDataSource,
    required AccountRemoteDataSource accountDataSource,
    required Duration profileGracePeriod,
    required String googleServerClientId,
  }) : _auth = authDataSource,
       _users = userDataSource,
       _account = accountDataSource,
       _profileGracePeriod = profileGracePeriod,
       _googleServerClientId = googleServerClientId;

  final SupabaseAuthDataSource _auth;
  final UserRemoteDataSource _users;
  final AccountRemoteDataSource _account;
  final Duration _profileGracePeriod;
  final String _googleServerClientId;

  @override
  Stream<AuthSession> watchSession() {
    // Auth emits on every token refresh; only a change of account, of email
    // confirmation or of the admin role changes the session. switchMap: the
    // profile stream never completes, so the previous one must be cancelled
    // when the account changes.
    return _auth
        .userChanges()
        .distinct((a, b) => _sessionKey(a) == _sessionKey(b))
        .switchMap<AuthSession>((user) {
          if (user == null) return Stream.value(const SignedOut());
          return _profileSession(user);
        });
  }

  static String? _sessionKey(User? user) => user == null
      ? null
      : '${user.id}|${user.emailConfirmedAt}|'
            '${SupabaseAuthDataSource.isAdmin(user)}';

  Stream<AuthSession> _profileSession(User user) {
    final verified = SupabaseAuthDataSource.isEmailVerified(user);
    final admin = SupabaseAuthDataSource.isAdmin(user);
    return _users.watch(user.id).switchMap<AuthSession>((dto) {
      if (dto != null) {
        return Stream.value(
          SignedIn(
            dto
                .toDomain(user.id)
                .copyWith(emailVerified: verified, isAdmin: admin),
          ),
        );
      }
      // A password sign-up has its profile created with the account; a
      // first Google sign-in has none yet. Give the row a moment to show up,
      // then ask for the role.
      return TimerStream(
        ProfileMissing(
          uid: user.id,
          email: user.email ?? '',
          displayName: _displayName(user),
        ),
        _profileGracePeriod,
      );
    });
  }

  static String? _displayName(User user) {
    final metadata = user.userMetadata ?? const <String, dynamic>{};
    final name = metadata['full_name'] ?? metadata['name'];
    return name is String && name.trim().isNotEmpty ? name.trim() : null;
  }

  @override
  Stream<void> get passwordRecoveries => _auth.passwordRecoveries;

  @override
  AsyncResult<AppUser> signIn({
    required String email,
    required String password,
  }) {
    return guard(() async {
      final user = await _auth.signIn(email: email, password: password);
      final dto = await _users.get(user.id);
      if (dto == null) throw const FailureException(_profileMissing);
      return dto
          .toDomain(user.id)
          .copyWith(
            emailVerified: SupabaseAuthDataSource.isEmailVerified(user),
            isAdmin: SupabaseAuthDataSource.isAdmin(user),
          );
    });
  }

  static const _profileMissing = AuthFailure(
    code: AuthFailureCode.profileMissing,
    message: 'Profil introuvable. Veuillez compléter votre profil.',
  );

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
      final user = await _auth.signUp(
        email: email,
        password: password,
        name: name.trim(),
        role: role.name,
      );
      // No session until the address is confirmed: the returned user tells
      // the form to send the person to their inbox.
      return AppUser(
        id: user.id,
        name: name.trim(),
        email: user.email ?? email.trim(),
        role: role,
        emailVerified: SupabaseAuthDataSource.isEmailVerified(user),
      );
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
      final profile = AppUser(
        id: user.id,
        name: name.trim(),
        email: user.email ?? '',
        role: role,
        emailVerified: SupabaseAuthDataSource.isEmailVerified(user),
      );
      await _users.create(user.id, UserDto.fromDomain(profile));
      return profile;
    });
  }

  @override
  AsyncResult<AppUser> updateProfile({required String name, String? bio}) {
    return guard(() async {
      final user = _auth.currentUser;
      if (user == null) throw const FailureException(AuthFailure.notSignedIn());
      await _users.updateProfile(user.id, name: name.trim(), bio: bio?.trim());
      // Read back: triggers normalise the row (trimmed name, empty bio).
      final dto = await _users.get(user.id);
      if (dto == null) throw const FailureException(_profileMissing);
      return dto
          .toDomain(user.id)
          .copyWith(
            emailVerified: SupabaseAuthDataSource.isEmailVerified(user),
            isAdmin: SupabaseAuthDataSource.isAdmin(user),
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
