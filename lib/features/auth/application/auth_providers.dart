import 'package:eventhub/core/config/app_config.dart';
import 'package:eventhub/core/firebase/firebase_providers.dart';
import 'package:eventhub/core/mock/mock_repositories.dart';
import 'package:eventhub/core/mock/mock_store.dart';
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
  if (ref.watch(appConfigProvider).useMockBackend) {
    return MockAuthRepository(ref.watch(mockStoreProvider));
  }
  return AuthRepositoryImpl(
    authDataSource: FirebaseAuthDataSource(ref.watch(firebaseAuthProvider)),
    userDataSource: UserRemoteDataSource(ref.watch(firestoreProvider)),
    profileGracePeriod: ref.watch(appConfigProvider).profileGracePeriod,
  );
}

/// Single source of truth for "who is logged in". Kept alive for the whole
/// app lifetime: the router and every feature derive from it.
@Riverpod(keepAlive: true)
Stream<AuthSession> authSession(Ref ref) =>
    ref.watch(authRepositoryProvider).watchSession();

/// Convenience view: the signed-in user or `null`.
@riverpod
AppUser? currentUser(Ref ref) =>
    ref.watch(authSessionProvider).value?.userOrNull;
