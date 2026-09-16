import 'package:eventhub/core/analytics/app_analytics.dart';
import 'package:eventhub/core/config/app_config.dart';
import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/firebase/firebase_providers.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/auth/application/auth_providers.dart';
import 'package:eventhub/features/auth/domain/entities/app_user.dart';
import 'package:eventhub/features/events/application/event_providers.dart';
import 'package:eventhub/features/notifications/application/push_dispatcher_provider.dart';
import 'package:eventhub/features/reservations/data/datasources/reservation_remote_data_source.dart';
import 'package:eventhub/features/reservations/data/repositories/reservation_repository_impl.dart';
import 'package:eventhub/features/reservations/domain/entities/checkout.dart';
import 'package:eventhub/features/reservations/domain/entities/reservation.dart';
import 'package:eventhub/features/reservations/domain/policies/reservation_policy.dart';
import 'package:eventhub/features/reservations/domain/repositories/reservation_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' hide AsyncResult;

part 'reservation_providers.g.dart';

@Riverpod(keepAlive: true)
ReservationRepository reservationRepository(Ref ref) =>
    ReservationRepositoryImpl(
      ReservationRemoteDataSource(
        ref.watch(firestoreProvider),
        ref.watch(firebaseAuthProvider),
        push: ref.watch(pushDispatcherProvider),
      ),
      clock: ref.watch(clockProvider),
    );

/// Réservations du compte connecté (son espace participant).
@riverpod
Stream<List<Reservation>> myReservations(Ref ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(const []);
  return ref.watch(reservationRepositoryProvider).watchByUser(user.id);
}

/// La réservation du compte connecté pour [eventId], s’il y en a une.
@riverpod
Stream<Reservation?> myReservationForEvent(Ref ref, String eventId) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);
  return ref
      .watch(reservationRepositoryProvider)
      .watchForEvent(eventId: eventId, userId: user.id);
}

/// Réservations confirmées d’un événement dont l’organisateur connecté est
/// propriétaire ou co-organisateur. Les règles refusent la requête à
/// quiconque n’appartient pas à l’équipe.
@riverpod
Stream<List<Reservation>> eventParticipants(Ref ref, String eventId) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(const []);
  return ref.watch(reservationRepositoryProvider).watchByEvent(eventId);
}

@riverpod
Stream<Reservation?> reservationById(Ref ref, String reservationId) =>
    ref.watch(reservationRepositoryProvider).watchById(reservationId);

@riverpod
class ReservationController extends _$ReservationController {
  @override
  FutureOr<void> build() {}

  /// [ReservationPolicy] s’exécute d’abord sur ce que l’écran affiche déjà
  /// (l’événement et la place), pour une réponse sans aller-retour ; la
  /// transaction la réévalue ensuite sur des lectures fraîches, et les
  /// règles tranchent.
  Future<Result<Reservation>> reserve(String eventId, {String? tierId}) async {
    final result = await _run<Reservation>((user) async {
      final event = ref.read(eventByIdProvider(eventId)).value;
      if (event != null) {
        final check = ReservationPolicy.canReserve(
          event: event,
          existing: ref.read(myReservationForEventProvider(eventId)).value,
          now: ref.read(clockProvider)(),
          tierId: tierId,
          userId: user.id,
        );
        if (check case Err(:final failure)) return Err<Reservation>(failure);
      }
      return ref
          .read(reservationRepositoryProvider)
          .reserve(eventId: eventId, participant: user, tierId: tierId);
    });
    if (result is Ok<Reservation>) {
      ref.read(appAnalyticsProvider).reservationConfirmed(eventId);
    }
    return result;
  }

  /// Une place payante (F-11) : indisponible sans serveur de paiement, et
  /// le repository le dit.
  Future<Result<CheckoutStart>> startCheckout({
    required String eventId,
    required String tierId,
  }) async {
    final result = await _run(
      (_) => ref
          .read(reservationRepositoryProvider)
          .startCheckout(eventId: eventId, tierId: tierId),
    );
    if (result is Ok<CheckoutStart>) {
      ref.read(appAnalyticsProvider).checkoutStarted(eventId, tierId);
    }
    return result;
  }

  Future<Result<void>> cancelPendingCheckout(String eventId) => _run(
    (_) => ref
        .read(reservationRepositoryProvider)
        .cancelPendingCheckout(eventId: eventId),
  );

  /// Remboursement d’un billet payé (F-11), en attente d’un serveur de
  /// paiement.
  Future<Result<void>> refund(String eventId) async {
    final result = await _run(
      (_) => ref.read(reservationRepositoryProvider).refund(eventId: eventId),
    );
    if (result is Ok<void>) {
      ref.read(appAnalyticsProvider).reservationCancelled(eventId);
    }
    return result;
  }

  Future<Result<void>> cancel(String reservationId) async {
    final result = await _run((user) async {
      final known = ref
          .read(myReservationsProvider)
          .value
          ?.where((r) => r.id == reservationId)
          .firstOrNull;
      if (known != null) {
        final check = ReservationPolicy.canCancel(
          reservation: known,
          userId: user.id,
        );
        if (check case Err(:final failure)) return Err<Reservation>(failure);
      }
      return ref
          .read(reservationRepositoryProvider)
          .cancel(reservationId: reservationId, userId: user.id);
    });
    if (result case Ok(:final value)) {
      ref.read(appAnalyticsProvider).reservationCancelled(value.eventId);
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
