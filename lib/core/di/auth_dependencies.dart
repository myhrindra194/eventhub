import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/platform_support.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/data/repositories/unsupported_auth_repository.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/login_with_google_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/domain/usecases/register_usecase.dart';
import '../../features/auth/domain/usecases/send_password_reset_email_usecase.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);

final firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);

final authAvailabilityProvider = Provider<bool>(
  (ref) => isFirebaseAuthSupported,
);

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(
    firebaseAuth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firestoreProvider),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (!isFirebaseAuthSupported) {
    return const UnsupportedAuthRepository();
  }

  return AuthRepositoryImpl(
    dataSource: ref.watch(authRemoteDataSourceProvider),
  );
});

final loginUseCaseProvider = Provider<LoginUseCase>(
  (ref) => LoginUseCase(ref.watch(authRepositoryProvider)),
);

final loginWithGoogleUseCaseProvider = Provider<LoginWithGoogleUseCase>(
  (ref) => LoginWithGoogleUseCase(ref.watch(authRepositoryProvider)),
);

final registerUseCaseProvider = Provider<RegisterUseCase>(
  (ref) => RegisterUseCase(ref.watch(authRepositoryProvider)),
);

final logoutUseCaseProvider = Provider<LogoutUseCase>(
  (ref) => LogoutUseCase(ref.watch(authRepositoryProvider)),
);

final sendPasswordResetEmailUseCaseProvider =
    Provider<SendPasswordResetEmailUseCase>(
      (ref) => SendPasswordResetEmailUseCase(ref.watch(authRepositoryProvider)),
    );
