import 'package:eventhub/core/supabase/timestamp_converter.dart';
import 'package:eventhub/features/checkin/domain/check_in_policy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'check_in_result_dto.freezed.dart';
part 'check_in_result_dto.g.dart';

/// JSON returned by `check_in_ticket`:
/// `{status, reservation_id?, user_name?, tier_name?, price_paid?,
/// currency?, scanned_at?}`.
@Freezed(toJson: false)
abstract class CheckInResultDto with _$CheckInResultDto {
  const CheckInResultDto._();

  @JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
  const factory CheckInResultDto({
    required String status,
    String? reservationId,
    String? userName,
    String? tierName,
    @NullableTimestampConverter() DateTime? scannedAt,
  }) = _CheckInResultDto;

  factory CheckInResultDto.fromJson(Map<String, dynamic> json) =>
      _$CheckInResultDtoFromJson(json);

  /// A status this build does not know (a newer server) never lets anyone
  /// in: it reads as an unknown ticket.
  CheckInVerdict toDomain() => CheckInVerdict(
    CheckInStatus.values.asNameMap()[status] ?? CheckInStatus.notFound,
    reservationId: reservationId,
    holderName: userName,
    tierName: tierName,
    checkedInAt: scannedAt,
  );
}
