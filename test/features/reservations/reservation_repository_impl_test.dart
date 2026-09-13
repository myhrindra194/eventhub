import 'package:flutter_test/flutter_test.dart';

import 'package:eventhub/features/reservations/data/datasources/reservation_remote_data_source.dart';
import 'package:eventhub/features/reservations/data/models/reservation_model.dart';
import 'package:eventhub/features/reservations/data/repositories/reservation_repository_impl.dart';
import 'package:eventhub/features/reservations/domain/entities/reservation.dart';

void main() {
  late FakeReservationRemoteDataSource remoteDataSource;
  late ReservationRepositoryImpl repository;

  setUp(() {
    remoteDataSource = FakeReservationRemoteDataSource();
    repository = ReservationRepositoryImpl(remoteDataSource: remoteDataSource);
  });

  test('getMesBillets mappe les modèles vers les entités', () async {
    remoteDataSource.userReservations = [
      ReservationModel(
        id: 'r-1',
        eventId: 'event-1',
        eventTitle: 'Tech Meetup',
        date: '20/11/2026 • 18:00',
        status: 'confirmed',
        seatInfo: '2 x GENERAL ACCESS',
        quantity: 2,
      ),
    ];

    final reservations = await repository.getMesBillets();

    expect(reservations.length, 1);
    final reservation = reservations.single;
    expect(reservation.eventId, 'event-1');
    expect(reservation.quantity, 2);
    expect(reservation.displayStatus, 'CONFIRMED');
  });

  test('getMesBillets expose isPast selon le statut', () async {
    remoteDataSource.userReservations = [
      ReservationModel(
        id: 'r-2',
        eventId: 'event-2',
        eventTitle: 'Past Event',
        date: '10/01/2026 • 10:00',
        status: 'past',
        seatInfo: '1 x GENERAL ACCESS',
      ),
    ];

    final reservation = (await repository.getMesBillets()).single;

    expect(reservation.isPast, isTrue);
    expect(reservation.displayStatus, 'PAST');
  });

  test('effectuerReservation délègue au datasource avec la quantité', () async {
    final reservation = Reservation(
      id: 'r-1',
      eventId: 'event-1',
      eventTitle: 'Tech Meetup',
      date: '20/11/2026 • 18:00',
      status: 'confirmed',
      seatInfo: '3 x GENERAL ACCESS',
      quantity: 3,
    );

    await repository.effectuerReservation(reservation);

    expect(remoteDataSource.saved.length, 1);
    final saved = remoteDataSource.saved.single;
    expect(saved.eventId, 'event-1');
    expect(saved.quantity, 3);
  });
}

/// Fake fait main : enregistre les réservations sauvegardées pour vérifier
/// le mapping effectué par le repository.
class FakeReservationRemoteDataSource implements ReservationRemoteDataSource {
  List<ReservationModel> userReservations = [];
  final List<ReservationModel> saved = [];

  @override
  Future<List<ReservationModel>> fetchUserReservations() async =>
      userReservations;

  @override
  Future<void> saveReservation(ReservationModel reservation) async {
    saved.add(reservation);
  }
}
