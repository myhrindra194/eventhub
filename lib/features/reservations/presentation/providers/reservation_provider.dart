import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/reservation_remote_data_source.dart';
import '../../data/repositories/reservation_repository_impl.dart';
import '../../domain/entities/reservation.dart';
import '../../domain/usecases/effectuer_reservation_usecase.dart';
import '../../domain/usecases/obtenir_billets_utilisateur_usecase.dart';

final reservationRepositoryProvider = Provider((ref) {
  return ReservationRepositoryImpl(
    remoteDataSource: ReservationRemoteDataSourceImpl(),
  );
});

final obtenirBilletsUseCaseProvider = Provider((ref) {
  return ObtenirBilletsUtilisateurUseCase(
    ref.read(reservationRepositoryProvider),
  );
});

final mesBilletsProvider = FutureProvider<List<Reservation>>((ref) async {
  final useCase = ref.read(obtenirBilletsUseCaseProvider);
  return await useCase();
});

final effectuerReservationUseCaseProvider = Provider((ref) {
  return EffectuerReservationUseCase(ref.read(reservationRepositoryProvider));
});
