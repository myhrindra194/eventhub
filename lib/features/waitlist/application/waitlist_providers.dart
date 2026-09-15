import 'package:eventhub/core/analytics/app_analytics.dart';
import 'package:eventhub/core/config/app_config.dart';
import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/firebase/firebase_providers.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/auth/application/auth_providers.dart';
import 'package:eventhub/features/auth/domain/entities/app_user.dart';
import 'package:eventhub/features/events/domain/entities/event.dart';
import 'package:eventhub/features/reservations/application/reservation_providers.dart';
import 'package:eventhub/features/waitlist/data/waitlist_remote_data_source.dart';
import 'package:eventhub/features/waitlist/data/waitlist_repository_impl.dart';
import 'package:eventhub/features/waitlist/domain/waitlist_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' hide AsyncResult;

part 'waitlist_providers.g.dart';

@Riverpod(keepAlive: true)
WaitlistRepository waitlistRepository(Ref ref) => WaitlistRepositoryImpl(
  WaitlistRemoteDataSource(ref.watch(firestoreProvider)),
);

/// Any signed-in account may wait (one account, two spaces); the event's
/// team is excluded by `WaitlistPolicy`, not here.
@riverpod
Stream<bool> isOnWaitlist(Ref ref, String eventId) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(false);
  return ref
      .watch(waitlistRepositoryProvider)
      .watchIsWaiting(eventId: eventId, userId: user.id);
}

/// Organizer view, capped at [WaitlistRepository.queueLengthCap].
@riverpod
Stream<int> waitlistLength(Ref ref, String eventId) =>
    ref.watch(waitlistRepositoryProvider).watchQueueLength(eventId);

@riverpod
class WaitlistController extends _$WaitlistController {
  @override
  FutureOr<void> build() {}

  Future<Result<void>> join(Event event) async {
    final result = await _run(
      (user) => ref
          .read(waitlistRepositoryProvider)
          .join(
            event: event,
            user: user,
            reservation: ref
                .read(myReservationForEventProvider(event.id))
                .value,
            now: ref.read(clockProvider)(),
          ),
    );
    if (result is Ok<void>) {
      ref.read(appAnalyticsProvider).waitlistJoined(event.id);
    }
    return result;
  }

  Future<Result<void>> leave(String eventId) => _run(
    (user) => ref
        .read(waitlistRepositoryProvider)
        .leave(eventId: eventId, userId: user.id),
  );

  Future<Result<void>> _run(
    AsyncResult<void> Function(AppUser user) action,
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
