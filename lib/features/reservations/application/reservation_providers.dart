import 'package:eventhub/core/analytics/app_analytics.dart';
import 'package:eventhub/core/config/app_config.dart';
import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/firebase/firebase_providers.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/auth/application/auth_providers.dart';
import 'package:eventhub/features/auth/domain/entities/app_user.dart';
import 'package:eventhub/features/events/application/event_providers.dart';
import 'package:eventhub/features/reservations/data/datasources/reservation_remote_data_source.dart';
import 'package:eventhub/features/reservations/data/repositories/reservation_repository_impl.dart';
import 'package:eventhub/features/reservations/domain/entities/reservation.dart';
import 'package:eventhub/features/reservations/domain/repositories/reservation_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' hide AsyncResult;

part 'reservation_providers.g.dart';

@Riverpod(keepAlive: true)
ReservationRepository reservationRepository(Ref ref) {
  return ReservationRepositoryImpl(
    ReservationRemoteDataSource(
      ref.watch(firestoreProvider),
      ref.watch(clockProvider),
    ),
  );
}

/// Reservations of the signed-in participant.
@riverpod
Stream<List<Reservation>> myReservations(Ref ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(const []);
  return ref.watch(reservationRepositoryProvider).watchByUser(user.id);
}

/// The signed-in participant's reservation for [eventId], if any.
@riverpod
Stream<Reservation?> myReservationForEvent(Ref ref, String eventId) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);
  return ref
      .watch(reservationRepositoryProvider)
      .watchForEvent(eventId: eventId, userId: user.id);
}

/// Active reservations of an event the signed-in organizer owns or
/// co-organizes. The query differs (owner: `organizerId ==`, team:
/// `eventId ==` only), because each is what the rules can prove.
@riverpod
Stream<List<Reservation>> eventParticipants(Ref ref, String eventId) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(const []);
  final event = ref.watch(eventByIdProvider(eventId)).value;
  final repo = ref.watch(reservationRepositoryProvider);
  if (event != null && event.isStaff(user.id)) {
    return repo.watchByEventForTeam(eventId);
  }
  return repo.watchByEvent(eventId: eventId, organizerId: user.id);
}

@riverpod
Stream<Reservation?> reservationById(Ref ref, String reservationId) =>
    ref.watch(reservationRepositoryProvider).watchById(reservationId);

@riverpod
class ReservationController extends _$ReservationController {
  @override
  FutureOr<void> build() {}

  Future<Result<Reservation>> reserve(String eventId) async {
    final result = await _run((user) {
      return ref
          .read(reservationRepositoryProvider)
          .reserve(eventId: eventId, participant: user);
    });
    if (result is Ok<Reservation>) {
      ref.read(appAnalyticsProvider).reservationConfirmed(eventId);
    }
    return result;
  }

  Future<Result<void>> cancel(String reservationId) async {
    final result = await _run((user) {
      return ref
          .read(reservationRepositoryProvider)
          .cancel(reservationId: reservationId, participant: user);
    });
    if (result is Ok<void>) {
      ref
          .read(appAnalyticsProvider)
          .reservationCancelled(reservationId.split('_').first);
    }
    return result;
  }

  Future<Result<T>> _run<T>(
    AsyncResult<T> Function(AppUser user) action,
  ) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return const Err(AuthFailure.notSignedIn());

    state = const AsyncLoading();
    final result = await action(user);
    state = switch (result) {
      Ok() => const AsyncData(null),
      Err(:final failure) => AsyncError(
        failure,
        failure.stackTrace ?? StackTrace.current,
      ),
    };
    return result;
  }
}
