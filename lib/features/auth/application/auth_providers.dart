import 'package:eventhub/core/config/app_config.dart';
import 'package:eventhub/core/supabase/supabase_providers.dart';
import 'package:eventhub/features/auth/data/datasources/account_remote_data_source.dart';
import 'package:eventhub/features/auth/data/datasources/supabase_auth_data_source.dart';
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
  final client = ref.watch(supabaseClientProvider);
  return AuthRepositoryImpl(
    authDataSource: SupabaseAuthDataSource(
      client.auth,
      redirectUrl: AppConfig.authRedirectUrl,
    ),
    userDataSource: UserRemoteDataSource(client),
    accountDataSource: AccountRemoteDataSource(client),
    profileGracePeriod: config.profileGracePeriod,
    googleServerClientId: config.googleServerClientId,
  );
}

/// Single source of truth for "who is logged in". Kept alive for the whole
/// app lifetime: the router and every feature derive from it.
@Riverpod(keepAlive: true)
Stream<AuthSession> authSession(Ref ref) =>
    ref.watch(authRepositoryProvider).watchSession();

/// Fires when a password-recovery link opens the app.
@Riverpod(keepAlive: true)
Stream<void> passwordRecovery(Ref ref) =>
    ref.watch(authRepositoryProvider).passwordRecoveries;

/// Convenience view: the signed-in user or `null`.
@riverpod
AppUser? currentUser(Ref ref) =>
    ref.watch(authSessionProvider).value?.userOrNull;
