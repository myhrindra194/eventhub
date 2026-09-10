import '../entities/reservation.dart';

abstract class ReservationRepository {
  Future<List<Reservation>> getMesBillets();
  Future<void> effectuerReservation(Reservation reservation);
  Future<void> rejoindreListeAttente(String eventId);
}
