import 'package:eventhub/core/config/app_config.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/auth/domain/entities/app_user.dart';
import 'package:eventhub/features/reservations/data/datasources/reservation_remote_data_source.dart';
import 'package:eventhub/features/reservations/domain/entities/checkout.dart';
import 'package:eventhub/features/reservations/domain/entities/reservation.dart';
import 'package:eventhub/features/reservations/domain/policies/reservation_policy.dart';
import 'package:eventhub/features/reservations/domain/repositories/reservation_repository.dart';

class ReservationRepositoryImpl implements ReservationRepository {
  const ReservationRepositoryImpl(this._remote, {required Clock clock})
    : _clock = clock;

  final ReservationRemoteDataSource _remote;
  final Clock _clock;

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

  /// La policy est confiée à la data source plutôt qu’exécutée ici : elle
  /// doit juger l’événement et la place *tels que la transaction les a
  /// lus*, sinon deux personnes prenant la dernière place la passeraient
  /// toutes les deux.
  @override
  AsyncResult<Reservation> reserve({
    required String eventId,
    required AppUser participant,
    String? tierId,
  }) => guard(
    () => _remote.reserve(
      eventId: eventId,
      participant: participant,
      tierId: tierId,
      check: (event, existing) => ReservationPolicy.canReserve(
        event: event,
        existing: existing,
        now: _clock(),
        tierId: tierId,
        userId: participant.id,
      ),
    ),
  );

  @override
  AsyncResult<Reservation> cancel({
    required String reservationId,
    required String userId,
  }) => guard(
    () => _remote.cancel(
      reservationId: reservationId,
      userId: userId,
      check: (reservation) =>
          ReservationPolicy.canCancel(reservation: reservation, userId: userId),
    ),
  );

  @override
  AsyncResult<CheckoutStart> startCheckout({
    required String eventId,
    required String tierId,
  }) async => const Err(ReservationPolicy.paymentUnavailable);

  @override
  AsyncResult<void> cancelPendingCheckout({required String eventId}) async =>
      const Err(ReservationPolicy.paymentUnavailable);

  @override
  AsyncResult<void> refund({required String eventId}) async =>
      const Err(ReservationPolicy.paymentUnavailable);
}
