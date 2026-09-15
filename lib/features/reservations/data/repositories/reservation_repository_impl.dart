import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/errors/failure_exception.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/auth/domain/entities/app_user.dart';
import 'package:eventhub/features/reservations/data/datasources/payment_functions_data_source.dart';
import 'package:eventhub/features/reservations/data/datasources/reservation_remote_data_source.dart';
import 'package:eventhub/features/reservations/domain/entities/checkout.dart';
import 'package:eventhub/features/reservations/domain/entities/reservation.dart';
import 'package:eventhub/features/reservations/domain/repositories/reservation_repository.dart';

class ReservationRepositoryImpl implements ReservationRepository {
  const ReservationRepositoryImpl(this._remote, this._payments);

  final ReservationRemoteDataSource _remote;
  final PaymentFunctionsDataSource _payments;

  @override
  Stream<List<Reservation>> watchByUser(String userId) =>
      _remote.watchByUser(userId);

  @override
  Stream<List<Reservation>> watchByEvent(String eventId) =>
      _remote.watchActiveByEvent(eventId);

  @override
  Stream<List<Reservation>> watchByOrganizer(String organizerId) =>
      _remote.watchByOrganizer(organizerId);

  @override
  Stream<Reservation?> watchForEvent({
    required String eventId,
    required String userId,
  }) => _remote.watchForEvent(eventId: eventId, userId: userId);

  @override
  Stream<Reservation?> watchById(String reservationId) =>
      _remote.watchById(reservationId);

  @override
  AsyncResult<Reservation> reserve({
    required String eventId,
    required AppUser participant,
    String? tierId,
  }) {
    return guard(() {
      _requireParticipant(participant);
      return _remote.reserve(eventId: eventId, tierId: tierId);
    });
  }

  @override
  AsyncResult<Reservation> cancel({required String reservationId}) =>
      guard(() => _remote.cancel(reservationId));

  @override
  AsyncResult<CheckoutStart> startCheckout({
    required String eventId,
    required String tierId,
  }) => guard(() => _payments.startCheckout(eventId: eventId, tierId: tierId));

  @override
  AsyncResult<void> cancelPendingCheckout({required String eventId}) =>
      guard(() => _payments.cancelPending(eventId));

  @override
  AsyncResult<void> refund({required String eventId}) =>
      guard(() => _payments.refund(eventId));

  /// The database refuses too; checked here so an organizer gets the precise
  /// sentence without a round trip.
  void _requireParticipant(AppUser user) {
    if (!user.isParticipant) {
      throw const FailureException(
        PermissionFailure(
          message: 'Seul un participant peut réserver une place.',
        ),
      );
    }
  }
}
