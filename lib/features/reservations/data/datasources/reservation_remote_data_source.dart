import '../models/reservation_model.dart';

abstract class ReservationRemoteDataSource {
  Future<List<ReservationModel>> fetchUserReservations();
  Future<void> saveReservation(ReservationModel reservation);
}

class ReservationRemoteDataSourceImpl implements ReservationRemoteDataSource {
  final List<ReservationModel> _reservations = [];

  @override
  Future<List<ReservationModel>> fetchUserReservations() async {
    await Future.delayed(const Duration(seconds: 1));
    return List.unmodifiable(_reservations);
  }

  @override
  Future<void> saveReservation(ReservationModel reservation) async {
    _reservations.removeWhere((item) => item.id == reservation.id);
    _reservations.add(reservation);
  }
}
