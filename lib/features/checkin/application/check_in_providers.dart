import 'dart:async';

import 'package:eventhub/core/analytics/app_analytics.dart';
import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/core/supabase/supabase_providers.dart';
import 'package:eventhub/features/auth/application/auth_providers.dart';
import 'package:eventhub/features/checkin/data/check_in_repository_impl.dart';
import 'package:eventhub/features/checkin/domain/check_in_policy.dart';
import 'package:eventhub/features/checkin/domain/check_in_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' hide AsyncResult;

part 'check_in_providers.g.dart';

@Riverpod(keepAlive: true)
CheckInRepository checkInRepository(Ref ref) =>
    CheckInRepositoryImpl(ref.watch(supabaseClientProvider));

@riverpod
Stream<Map<String, DateTime>> eventCheckIns(Ref ref, String eventId) =>
    ref.watch(checkInRepositoryProvider).watchCheckIns(eventId);

/// One scan at the door: the local precheck (CheckInPolicy), then the
/// server's atomic verdict.
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
    final Result<CheckInVerdict> result;
    if (CheckInPolicy.precheck(reservationId: reservationId, code: code)
        case final verdict?) {
      result = Ok(verdict);
    } else {
      state = const AsyncLoading();
      result = await ref
          .read(checkInRepositoryProvider)
          .checkIn(eventId: eventId, reservationId: reservationId);
      state = const AsyncData(null);
    }
    if (result case Ok(:final value)) {
      ref.read(appAnalyticsProvider).ticketScanned(value.status.name);
    }
    return result;
  }
}
