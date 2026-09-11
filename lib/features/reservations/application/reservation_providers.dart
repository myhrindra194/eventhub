import 'package:eventhub/core/config/app_config.dart';
import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/firebase/firebase_providers.dart';
import 'package:eventhub/core/mock/mock_repositories.dart';
import 'package:eventhub/core/mock/mock_store.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/auth/application/auth_providers.dart';
import 'package:eventhub/features/auth/domain/entities/app_user.dart';
import 'package:eventhub/features/reservations/data/datasources/reservation_remote_data_source.dart';
import 'package:eventhub/features/reservations/data/repositories/reservation_repository_impl.dart';
import 'package:eventhub/features/reservations/domain/entities/reservation.dart';
import 'package:eventhub/features/reservations/domain/repositories/reservation_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' hide AsyncResult;

part 'reservation_providers.g.dart';

@Riverpod(keepAlive: true)
ReservationRepository reservationRepository(Ref ref) {
  if (ref.watch(appConfigProvider).useMockBackend) {
    return MockReservationRepository(
      ref.watch(mockStoreProvider),
      ref.watch(clockProvider),
    );
  }
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

/// Active reservations of one of the signed-in organizer's events.
@riverpod
Stream<List<Reservation>> eventParticipants(Ref ref, String eventId) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(const []);
  return ref
      .watch(reservationRepositoryProvider)
      .watchByEvent(eventId: eventId, organizerId: user.id);
}

@riverpod
Stream<Reservation?> reservationById(Ref ref, String reservationId) =>
    ref.watch(reservationRepositoryProvider).watchById(reservationId);

@riverpod
class ReservationController extends _$ReservationController {
  @override
  FutureOr<void> build() {}

  Future<Result<Reservation>> reserve(String eventId) {
    return _run((user) {
      return ref
          .read(reservationRepositoryProvider)
          .reserve(eventId: eventId, participant: user);
    });
  }

  Future<Result<void>> cancel(String reservationId) {
    return _run((user) {
      return ref
          .read(reservationRepositoryProvider)
          .cancel(reservationId: reservationId, participant: user);
    });
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
