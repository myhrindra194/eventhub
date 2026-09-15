import 'package:eventhub/core/config/app_config.dart';
import 'package:eventhub/features/auth/application/auth_providers.dart';
import 'package:eventhub/features/events/application/event_providers.dart';
import 'package:eventhub/features/organizer/domain/organizer_insights.dart';
import 'package:eventhub/features/reservations/application/reservation_providers.dart';
import 'package:eventhub/features/reservations/domain/entities/reservation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'organizer_providers.g.dart';

/// Every reservation on the signed-in organizer's events, all statuses.
@riverpod
Stream<List<Reservation>> organizerReservations(Ref ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null || !user.isOrganizer) return Stream.value(const []);
  return ref.watch(reservationRepositoryProvider).watchByOrganizer(user.id);
}

@riverpod
AsyncValue<OrganizerStats> organizerStats(Ref ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const AsyncLoading();
  final now = ref.watch(clockProvider)();
  return _combine(
    ref.watch(organizerEventsProvider(user.id)),
    ref.watch(organizerReservationsProvider),
    (events, reservations) => OrganizerStats.compute(
      events: events,
      reservations: reservations,
      now: now,
    ),
  );
}

/// Upcoming events needing attention — also drives the badge on the
/// "Alertes" tab.
@riverpod
AsyncValue<List<OrganizerAlert>> organizerWatchlist(Ref ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const AsyncData([]);
  final now = ref.watch(clockProvider)();
  return ref
      .watch(organizerEventsProvider(user.id))
      .whenData(
        (events) => OrganizerAlerts.watchlist(events: events, now: now),
      );
}

@riverpod
AsyncValue<List<OrganizerAlert>> organizerActivity(Ref ref) => ref
    .watch(organizerReservationsProvider)
    .whenData((list) => OrganizerAlerts.activity(reservations: list));

/// Joins two async sources: the first error wins, then loading, then data.
AsyncValue<T> _combine<A extends Object, B extends Object, T>(
  AsyncValue<A> a,
  AsyncValue<B> b,
  T Function(A, B) combine,
) {
  for (final value in [a, b]) {
    if (value.hasError) {
      return AsyncError(value.error!, value.stackTrace ?? StackTrace.current);
    }
  }
  final va = a.value;
  final vb = b.value;
  if (va == null || vb == null) return const AsyncLoading();
  return AsyncData(combine(va, vb));
}
