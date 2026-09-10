import '../repositories/reservation_repository.dart';

class RejoindreListeAttenteUseCase {
  final ReservationRepository repository;

  RejoindreListeAttenteUseCase(this.repository);

  Future<void> call(String eventId) async {
    return await repository.rejoindreListeAttente(eventId);
  }
}
