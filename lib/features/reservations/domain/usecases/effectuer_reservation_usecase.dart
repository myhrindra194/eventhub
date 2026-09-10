import '../repositories/reservation_repository.dart';
import '../entities/reservation.dart';

class EffectuerReservationUseCase {
  final ReservationRepository repository;

  EffectuerReservationUseCase(this.repository);

  Future<void> call(Reservation reservation) async {
    return await repository.effectuerReservation(reservation);
  }
}
