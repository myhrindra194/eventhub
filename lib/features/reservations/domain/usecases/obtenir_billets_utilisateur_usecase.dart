import '../entities/reservation.dart';
import '../repositories/reservation_repository.dart';

class ObtenirBilletsUtilisateurUseCase {
  final ReservationRepository repository;

  ObtenirBilletsUtilisateurUseCase(this.repository);

  Future<List<Reservation>> call() async {
    return await repository.getMesBillets();
  }
}
