import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/errors/failure_exception.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/auth/domain/entities/app_user.dart';
import 'package:eventhub/features/reservations/data/datasources/reservation_remote_data_source.dart';
import 'package:eventhub/features/reservations/domain/entities/reservation.dart';
import 'package:eventhub/features/reservations/domain/repositories/reservation_repository.dart';

class ReservationRepositoryImpl implements ReservationRepository {
  const ReservationRepositoryImpl(this._remote);

  final ReservationRemoteDataSource _remote;

  @override
  Stream<List<Reservation>> watchByUser(String userId) =>
      _remote.watchByUser(userId);

  @override
  Stream<List<Reservation>> watchByEvent({
    required String eventId,
    required String organizerId,
  }) => _remote.watchActiveByEvent(eventId: eventId, organizerId: organizerId);

  @override
  Stream<Reservation?> watchForEvent({
    required String eventId,
    required String userId,
  }) => _remote.watchById(
    Reservation.composeId(eventId: eventId, userId: userId),
  );

  @override
  Stream<Reservation?> watchById(String reservationId) =>
      _remote.watchById(reservationId);

  @override
  AsyncResult<Reservation> reserve({
    required String eventId,
    required AppUser participant,
  }) {
    return guard(() {
      if (!participant.isParticipant) {
        throw const FailureException(
          PermissionFailure(
            message: 'Seul un participant peut réserver une place.',
          ),
        );
      }
      return _remote.reserve(eventId: eventId, participant: participant);
    });
  }

  @override
  AsyncResult<void> cancel({
    required String reservationId,
    required AppUser participant,
  }) => guard(
    () =>
        _remote.cancel(reservationId: reservationId, participant: participant),
  );
}
