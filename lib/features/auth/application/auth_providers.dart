import 'package:eventhub/core/backend/api_client.dart';
import 'package:eventhub/core/config/app_config.dart';
import 'package:eventhub/core/firebase/firebase_providers.dart';
import 'package:eventhub/features/auth/data/datasources/account_remote_data_source.dart';
import 'package:eventhub/features/auth/data/datasources/firebase_auth_data_source.dart';
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
    // Le mail de bienvenue part du Worker : le résultat n'intéresse personne,
    // l'inscription est déjà réussie quand il est demandé.
    onAccountCreated: () async {
      await ref.read(apiClientProvider).post('/v1/welcome');
    },
  );
}

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
