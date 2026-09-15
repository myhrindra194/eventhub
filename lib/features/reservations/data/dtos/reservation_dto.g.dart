// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reservation_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ReservationDto _$ReservationDtoFromJson(
  Map<String, dynamic> json,
) => _ReservationDto(
  eventId: json['eventId'] as String? ?? '',
  userId: json['userId'] as String? ?? '',
  organizerId: json['organizerId'] as String? ?? '',
  userName: json['userName'] as String,
  userEmail: json['userEmail'] as String,
  eventTitle: json['eventTitle'] as String,
  eventStartsAt: const TimestampConverter().fromJson(
    json['eventStartsAt'] as Object,
  ),
  eventLocation: json['eventLocation'] as String,
  status: $enumDecode(
    _$ReservationStatusEnumMap,
    json['status'],
    unknownValue: ReservationStatus.cancelled,
  ),
  reservedAt: const TimestampConverter().fromJson(json['reservedAt'] as Object),
  cancelledAt: const NullableTimestampConverter().fromJson(json['cancelledAt']),
  cancelledBy: json['cancelledBy'] as String?,
  tierId: json['tierId'] as String?,
  tierName: json['tierName'] as String?,
  pricePaid: (json['pricePaid'] as num?)?.toInt() ?? 0,
);

const _$ReservationStatusEnumMap = {
  ReservationStatus.confirmed: 'confirmed',
  ReservationStatus.pending: 'pending',
  ReservationStatus.cancelled: 'cancelled',
};
