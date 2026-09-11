import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/errors/failure_exception.dart';
import 'package:eventhub/core/result/result.dart';
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
    required Duration profileGracePeriod,
  }) : _auth = authDataSource,
       _users = userDataSource,
       _profileGracePeriod = profileGracePeriod;

  final FirebaseAuthDataSource _auth;
  final UserRemoteDataSource _users;
  final Duration _profileGracePeriod;

  @override
  Stream<AuthSession> watchSession() {
    // switchMap (not asyncExpand): a Firestore snapshot stream never
    // completes, so the previous profile subscription must be cancelled when
    // the Firebase user changes (sign-out / account switch).
    return _auth.authStateChanges().switchMap<AuthSession>((user) {
      if (user == null) return Stream.value(const SignedOut());
      return _sessionFor(user);
    }).distinct();
  }

  Stream<AuthSession> _sessionFor(User user) {
    return _users.watch(user.uid).switchMap<AuthSession>((dto) {
      if (dto != null) return Stream.value(SignedIn(dto.toDomain(user.uid)));
      // Right after sign-up the auth user exists before the profile document
      // is written. Tolerate that window; if the profile still has not shown
      // up after the grace period, surface `ProfileMissing`.
      return TimerStream(
        ProfileMissing(uid: user.uid, email: user.email ?? ''),
        _profileGracePeriod,
      );
    });
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
      return dto.toDomain(user.uid);
    });
  }

  @override
  AsyncResult<AppUser> signUp({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) {
    return guard(() async {
      final user = await _auth.signUp(email: email, password: password);
      return _createProfile(user, name: name, role: role);
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
    );
    await _users.create(user.uid, UserDto.fromDomain(profile));
    return profile;
  }

  @override
  AsyncResult<void> sendPasswordReset({required String email}) =>
      guard(() => _auth.sendPasswordReset(email));

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
  AsyncResult<void> signOut() => guard(_auth.signOut);
}
