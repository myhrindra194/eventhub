import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/auth_dependencies.dart';
import '../../data/datasources/reservation_remote_data_source.dart';
import '../../data/repositories/reservation_repository_impl.dart';
import '../../domain/entities/reservation.dart';
import '../../domain/repositories/reservation_repository.dart';
import '../../domain/usecases/effectuer_reservation_usecase.dart';
import '../../domain/usecases/obtenir_billets_utilisateur_usecase.dart';
import '../../domain/usecases/create_reservation_usecase.dart';

final reservationRepositoryProvider = Provider<ReservationRepository>((ref) {
  return ReservationRepositoryImpl(
    remoteDataSource: ReservationRemoteDataSourceImpl(
      firestore: ref.watch(firestoreProvider),
      firebaseAuth: ref.watch(firebaseAuthProvider),
    ),
  );
});

final obtenirBilletsUseCaseProvider =
    Provider<ObtenirBilletsUtilisateurUseCase>((ref) {
      return ObtenirBilletsUtilisateurUseCase(
        ref.watch(reservationRepositoryProvider),
      );
    });

final mesBilletsProvider = FutureProvider<List<Reservation>>((ref) async {
  final useCase = ref.watch(obtenirBilletsUseCaseProvider);
  return useCase();
});

final effectuerReservationUseCaseProvider =
    Provider<EffectuerReservationUseCase>((ref) {
      return EffectuerReservationUseCase(
        ref.watch(reservationRepositoryProvider),
      );
    });

final createReservationUseCaseProvider = Provider<CreateReservationUseCase>(
  (ref) => CreateReservationUseCase(),
);
