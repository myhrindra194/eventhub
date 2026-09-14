import 'dart:async';

import 'package:eventhub/core/analytics/app_analytics.dart';
import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/firebase/firebase_providers.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/auth/application/auth_providers.dart';
import 'package:eventhub/features/checkin/data/check_in_repository_impl.dart';
import 'package:eventhub/features/checkin/domain/check_in_policy.dart';
import 'package:eventhub/features/checkin/domain/check_in_repository.dart';
import 'package:eventhub/features/reservations/application/reservation_providers.dart';
import 'package:eventhub/features/reservations/domain/entities/reservation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' hide AsyncResult;

part 'check_in_providers.g.dart';

@Riverpod(keepAlive: true)
CheckInRepository checkInRepository(Ref ref) =>
    CheckInRepositoryImpl(ref.watch(firestoreProvider));

@riverpod
Stream<Map<String, DateTime>> eventCheckIns(Ref ref, String eventId) =>
    ref.watch(checkInRepositoryProvider).watchCheckIns(eventId);

/// One scan at the door: read, judge (CheckInPolicy), record.
@riverpod
class CheckInController extends _$CheckInController {
  @override
  FutureOr<void> build() {}

  Future<Result<CheckInVerdict>> scan({
    required String eventId,
    required String reservationId,
    required String code,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null || !user.isOrganizer) {
      return const Err(AuthFailure.notSignedIn());
    }
    state = const AsyncLoading();
    final result = await _scan(user.id, eventId, reservationId, code);
    state = const AsyncData(null);
    if (result case Ok(:final value)) {
      ref.read(appAnalyticsProvider).ticketScanned(value.status.name);
    }
    return result;
  }

  Future<Result<CheckInVerdict>> _scan(
    String organizerId,
    String eventId,
    String reservationId,
    String code,
  ) async {
    final reservation = await _readReservation(reservationId);
    final repo = ref.read(checkInRepositoryProvider);

    DateTime? checkedInAt;
    if (reservation != null && reservation.eventId == eventId) {
      switch (await repo.checkedInAt(
        eventId: eventId,
        reservationId: reservationId,
      )) {
        case Ok(:final value):
          checkedInAt = value;
        case Err(:final failure):
          return Err(failure);
      }
    }

    final verdict = CheckInPolicy.evaluate(
      eventId: eventId,
      code: code,
      reservation: reservation,
      checkedInAt: checkedInAt,
    );
    if (!verdict.isAdmitted) return Ok(verdict);

    switch (await repo.record(
      eventId: eventId,
      reservationId: reservationId,
      organizerId: organizerId,
    )) {
      case Ok(value: true):
        return Ok(verdict);
      case Ok():
        return Ok(
          CheckInVerdict(
            CheckInStatus.alreadyCheckedIn,
            reservation: reservation,
            checkedInAt: DateTime.now(),
          ),
        );
      case Err(:final failure):
        return Err(failure);
    }
  }

  /// A reservation of another organizer's event is unreadable (rules): for
  /// the door, that is the same as a ticket that does not exist.
  Future<Reservation?> _readReservation(String id) async {
    try {
      return await ref
          .read(reservationRepositoryProvider)
          .watchById(id)
          .first
          .timeout(const Duration(seconds: 10));
    } on Object {
      return null;
    }
  }
}
