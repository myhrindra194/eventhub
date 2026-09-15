// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'check_in_result_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CheckInResultDto _$CheckInResultDtoFromJson(Map<String, dynamic> json) =>
    _CheckInResultDto(
      status: json['status'] as String,
      reservationId: json['reservation_id'] as String?,
      userName: json['user_name'] as String?,
      tierName: json['tier_name'] as String?,
      scannedAt: const NullableTimestampConverter().fromJson(
        json['scanned_at'],
      ),
    );
