import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/core/supabase/db.dart';
import 'package:eventhub/core/supabase/supabase_providers.dart';
import 'package:eventhub/core/supabase/timestamp_converter.dart';
import 'package:eventhub/features/checkin/data/check_in_result_dto.dart';
import 'package:eventhub/features/checkin/domain/check_in_policy.dart';
import 'package:eventhub/features/checkin/domain/check_in_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CheckInRepositoryImpl implements CheckInRepository {
  const CheckInRepositoryImpl(this._client);

  final SupabaseClient _client;

  /// Feeds the live "12 / 80" counter and "Entré · HH:mm" on the guest list.
  /// `reservation_id` is the table's primary key: one row per ticket.
  @override
  Stream<Map<String, DateTime>> watchCheckIns(String eventId) => _client
      .from(Tables.checkins)
      .stream(primaryKey: ['reservation_id'])
      .eq('event_id', eventId)
      .map(
        (rows) => {
          for (final row in rows)
            row['reservation_id'] as String: const TimestampConverter()
                .fromJson(row['scanned_at'] as Object),
        },
      )
      .resilient('checkins:$eventId');

  @override
  AsyncResult<CheckInVerdict> checkIn({
    required String eventId,
    required String reservationId,
  }) => guard(() async {
    final json = await _client.rpc<dynamic>(
      Rpc.checkInTicket,
      params: {'p_event_id': eventId, 'p_reservation_id': reservationId},
    );
    return CheckInResultDto.fromJson(
      Map<String, dynamic>.from(json as Map),
    ).toDomain();
  });
}
