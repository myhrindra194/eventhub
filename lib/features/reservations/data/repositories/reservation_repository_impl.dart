import '../../domain/entities/reservation.dart';
import '../../domain/repositories/reservation_repository.dart';
import '../datasources/reservation_remote_data_source.dart';
import '../models/reservation_model.dart';

class ReservationRepositoryImpl implements ReservationRepository {
  final ReservationRemoteDataSource remoteDataSource;

  ReservationRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Reservation>> getMesBillets() async {
    final models = await remoteDataSource.fetchUserReservations();
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<void> effectuerReservation(Reservation reservation) async {
    await remoteDataSource.saveReservation(
      ReservationModel(
        id: reservation.id,
        eventTitle: reservation.eventTitle,
        date: reservation.date,
        status: reservation.status,
        seatInfo: reservation.seatInfo,
      ),
    );
  }

  @override
  Future<void> rejoindreListeAttente(String eventId) async {}
}
