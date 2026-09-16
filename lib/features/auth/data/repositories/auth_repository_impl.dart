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
    Future<void> Function()? onAccountCreated,
  }) : _onAccountCreated = onAccountCreated,
       _auth = authDataSource,
       _users = userDataSource,
       _account = accountDataSource,
       _profileGracePeriod = profileGracePeriod,
       _clock = clock;

  final FirebaseAuthDataSource _auth;
  final UserRemoteDataSource _users;
  final AccountRemoteDataSource _account;
  final Duration _profileGracePeriod;
  final DateTime Function() _clock;

  /// Appelé une fois le profil d'un nouveau compte écrit : c'est le mail de
  /// bienvenue, envoyé par le Worker `eventhub-api`. Jamais attendu et jamais
  /// fatal — un mail perdu ne doit pas faire échouer une inscription réussie.
  final Future<void> Function()? _onAccountCreated;

  /// Ce que l'écran d'inscription sait du compte sur le point d'être créé :
  /// le nom saisi et le rôle choisi.
  ///
  /// **Pourquoi avant la création du compte Auth.** Dès que Firebase crée le
  /// compte, `userChanges()` émet, le flux de session constate l'absence de
  /// profil et l'écrit lui-même — souvent *avant* que [signUp] n'ait repris
  /// la main. Sans cette intention posée en amont, ce profil partait avec les
  /// valeurs par défaut (participant, nom tiré de l'adresse), et l'écriture de
  /// l'inscription arrivait ensuite sur un document existant, que les règles
  /// refusent de réécrire : le rôle « Organisateur » choisi était perdu.
  ({String? name, UserRole role})? _signUpIntent;

  void _announceNewAccount() {
    final callback = _onAccountCreated;
    if (callback == null) return;
    unawaited(callback().catchError((Object _) {}));
  }

  /// L'écriture du profil de chaque compte, partagée par tous ceux qui la
  /// demandent.
  ///
  /// Le flux de session et [signUp] veulent tous deux créer le profil d'un
  /// compte neuf ; le flux ré-émet en plus `null` à chaque passage tant que le
  /// document n'existe pas. Une seule écriture doit partir : les suivants
  /// attendent la même `Future` au lieu d'en lancer une concurrente.
  final _profileWrites = <String, Future<void>>{};

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

  /// Écrit le profil d'un compte qui n'en a pas, une seule fois.
  ///
  /// Le nom et le rôle viennent, par ordre de préférence : des arguments,
  /// de l'intention d'inscription ([_signUpIntent]), puis de ce que Firebase
  /// sait déjà du compte. Un échec retire l'écriture de la table pour qu'un
  /// appel suivant puisse retenter, puis se propage à l'appelant.
  Future<void> _ensureProfile(User user, {String? name, UserRole? role}) {
    final inFlight = _profileWrites[user.uid];
    if (inFlight != null) return inFlight;

    final intent = _signUpIntent;
    final write = () async {
      await _users.create(
        user.uid,
        name: name ?? intent?.name ?? _initialName(user),
        email: user.email ?? '',
        intendedRole: role ?? intent?.role ?? UserRole.participant,
      );
      _announceNewAccount();
    }();
    _profileWrites[user.uid] = write;
    return write.catchError((Object error, StackTrace stackTrace) {
      _profileWrites.remove(user.uid);
      Error.throwWithStackTrace(error, stackTrace);
    });
  }

  /// Côté flux de session : aucune erreur n'est remontée, l'utilisateur n'a
  /// rien demandé. Le délai de grâce exposera l'écran de rattrapage si le
  /// problème persiste.
  Future<void> _createMissingProfile(User user) =>
      _ensureProfile(user).catchError((Object _) {});

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
  AsyncResult<void> signInWithGoogle({
    UserRole intendedRole = UserRole.participant,
  }) {
    _signUpIntent = (name: null, role: intendedRole);
    return guard(_auth.signInWithGoogle);
  }

  @override
  AsyncResult<AppUser> signUp({
    required String name,
    required String email,
    required String password,
    required UserRole intendedRole,
  }) {
    return guard(() async {
      final trimmed = name.trim();
      // Posée avant la création du compte : voir [_signUpIntent].
      _signUpIntent = (name: trimmed, role: intendedRole);
      try {
        final user = await _auth.signUp(
          email: email,
          password: password,
          name: trimmed,
        );
        final address = user.email ?? email.trim();
        // Rejoint l'écriture déjà lancée par le flux de session s'il a été
        // plus rapide ; sinon la lance. Dans les deux cas, avec ce rôle-ci. Le
        // mail de bienvenue part de cette écriture unique.
        await _ensureProfile(user, name: trimmed, role: intendedRole);
        return AppUser(
          id: user.uid,
          name: trimmed,
          email: address,
          role: intendedRole,
          intendedRole: intendedRole,
          emailVerified: user.emailVerified,
        );
      } finally {
        _signUpIntent = null;
      }
    });
  }

  @override
  AsyncResult<AppUser> completeProfile({required String name}) {
    return guard(() async {
      final user = _auth.currentUser;
      if (user == null) throw const FailureException(AuthFailure.notSignedIn());
      final trimmed = name.trim();
      final email = user.email ?? '';
      // Même écriture unique que l'inscription et le flux de session.
      await _ensureProfile(user, name: trimmed);
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
  AsyncResult<bool> refreshEmailVerification() => guard(() async {
    final verified = await _auth.refreshEmailVerification();
    // Un organisateur qui vient de confirmer son adresse devient trouvable
    // pour les invitations de co-organisateurs.
    final user = _auth.currentUser;
    if (verified && user != null) {
      final dto = await _users.get(user.uid);
      if (dto != null && dto.role == UserRole.organizer) {
        await _users
            .registerOrganizerEmail(user.uid, user.email ?? dto.email)
            .catchError((Object _) {});
      }
    }
    return verified;
  });

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
