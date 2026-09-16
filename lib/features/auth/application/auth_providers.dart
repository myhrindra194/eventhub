import 'package:eventhub/core/config/app_config.dart';
import 'package:eventhub/core/firebase/firebase_providers.dart';
import 'package:eventhub/features/auth/data/datasources/account_remote_data_source.dart';
import 'package:eventhub/features/auth/data/datasources/firebase_auth_data_source.dart';
import 'package:eventhub/features/auth/data/datasources/profile_photo_picker.dart';
import 'package:eventhub/features/auth/data/datasources/user_remote_data_source.dart';
import 'package:eventhub/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:eventhub/features/auth/domain/entities/app_user.dart';
import 'package:eventhub/features/auth/domain/entities/auth_session.dart';
import 'package:eventhub/features/auth/domain/repositories/auth_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_providers.g.dart';

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  final config = ref.watch(appConfigProvider);
  final db = ref.watch(firestoreProvider);
  return AuthRepositoryImpl(
    authDataSource: FirebaseAuthDataSource(
      ref.watch(firebaseAuthProvider),
      googleServerClientId: config.googleServerClientId,
    ),
    userDataSource: UserRemoteDataSource(db),
    accountDataSource: AccountRemoteDataSource(db),
    profileGracePeriod: config.profileGracePeriod,
    clock: ref.watch(clockProvider),
  );
}

/// Le sélecteur de photo de profil.
///
/// Exposé comme dépendance plutôt qu'instancié dans l'écran : il ouvre la
/// galerie ou l'appareil photo par un canal de plateforme, donc un test de
/// widget doit pouvoir le remplacer pour ne rien ouvrir du tout.
@Riverpod(keepAlive: true)
ProfilePhotoPicker profilePhotoPicker(Ref ref) => const ProfilePhotoPicker();

/// Source de vérité unique pour « qui est connecté ». Maintenue en vie
/// pendant toute la durée de vie de l’application : le router et chacune des
/// features en dérivent.
@Riverpod(keepAlive: true)
Stream<AuthSession> authSession(Ref ref) =>
    ref.watch(authRepositoryProvider).watchSession();

/// Se déclenche lorsqu’un lien de récupération de mot de passe ouvre
/// l’application.
@Riverpod(keepAlive: true)
Stream<void> passwordRecovery(Ref ref) =>
    ref.watch(authRepositoryProvider).passwordRecoveries;

/// Vue de confort : l’utilisateur connecté, ou `null`.
@riverpod
AppUser? currentUser(Ref ref) =>
    ref.watch(authSessionProvider).value?.userOrNull;
