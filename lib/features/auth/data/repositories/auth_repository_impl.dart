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

  /// Comptes dont le profil manquant est déjà en cours de création.
  ///
  /// Le flux de profil ré-émet `null` à chaque passage tant que le document
  /// n'existe pas ; sans ce garde-fou, chaque émission relancerait une
  /// écriture concurrente pour le même compte.
  final _pendingProfiles = <String>{};

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
    // Auth émet à chaque rafraîchissement de token ; seul un changement de
    // compte ou de vérification d’e-mail change la session. switchMap : le
    // flux de profil ne se termine jamais, il faut donc annuler le précédent
    // quand le compte change (et avant que son écouteur ne soit refusé à la
    // déconnexion).
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
        // La modération a suspendu le compte alors qu’il était connecté.
        unawaited(_auth.signOut());
        return Stream.value(const SignedOut());
      }
      if (dto != null) {
        return Stream.value(SignedIn(_toUser(user, dto, isAdmin: admin)));
      }
      // Le compte existe, son profil non : première connexion Google, ou
      // inscription interrompue avant l'écriture du document.
      //
      // On ne réclame rien à l'utilisateur. Tout ce qu'un écran de complétion
      // lui ferait taper, Firebase le sait déjà — c'est d'ailleurs pourquoi
      // cet écran pré-remplissait le champ avant de demander de le valider.
      // On écrit donc le profil nous-mêmes et la connexion se poursuit vers
      // l'application ; enrichir son profil reste une démarche volontaire,
      // depuis l'écran de profil.
      unawaited(_createMissingProfile(user));

      // Filet de sécurité, pas parcours nominal : si l'écriture échoue
      // (hors ligne, règles refusées), la session bascule en `ProfileMissing`
      // au bout du délai de grâce et l'écran de rattrapage prend le relais.
      // Une écriture réussie fait émettre le document à `watch`, ce qui
      // annule ce minuteur avant son terme.
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

  /// Écrit le profil d'un compte qui n'en a pas, sans rien demander.
  ///
  /// Un échec n'est pas remonté : l'utilisateur n'a rien demandé, donc rien
  /// à réparer. Le compte est simplement retiré des créations en cours pour
  /// qu'une émission suivante puisse retenter, et le délai de grâce finira
  /// par exposer l'écran de rattrapage si le problème persiste.
  Future<void> _createMissingProfile(User user) async {
    if (!_pendingProfiles.add(user.uid)) return;
    try {
      await _users.create(
        user.uid,
        name: _initialName(user),
        email: user.email ?? '',
      );
    } on Object {
      _pendingProfiles.remove(user.uid);
    }
  }

  /// Le meilleur nom disponible sans poser de question : celui du compte
  /// Google, sinon la partie locale de l'adresse. Le repli n'est pas une
  /// coquetterie — les règles imposent un nom d'au moins deux caractères, et
  /// une adresse de la forme `a@…` n'en fournirait qu'un.
  static String _initialName(User user) {
    final declared = _displayName(user);
    if (declared != null) return declared;
    final local = (user.email ?? '').split('@').first.trim();
    return local.length >= 2 ? local : 'Participant';
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
      // Ne fait jamais échouer l’inscription : le bandeau propose de renvoyer
      // le lien.
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
      // Les règles lisent `email_verified` dans le token : on le met à jour.
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
  AsyncResult<AppUser> updateProfile({
    required String name,
    String? bio,
    String? photoUrl,
    String? coverUrl,
    bool updatePhotos = false,
  }) {
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
        photoUrl: photoUrl,
        coverUrl: coverUrl,
        updatePhotos: updatePhotos,
        isOrganizer: current.role == UserRole.organizer,
      );
      return _toUser(
        user,
        current.copyWith(
          name: name.trim(),
          bio: trimmedBio == null
              ? current.bio
              : (trimmedBio.isEmpty ? null : trimmedBio),
          // Sans [updatePhotos], les photos ne sont pas touchées : c'est ce
          // qui distingue « je ne change que mon nom » de « je retire ma
          // photo », les deux passant par un `null`.
          photoUrl: updatePhotos ? photoUrl : current.photoUrl,
          coverUrl: updatePhotos ? coverUrl : current.coverUrl,
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
      // D’abord : un mot de passe erroné doit tout arrêter avant que la
      // moindre donnée ne bouge.
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
