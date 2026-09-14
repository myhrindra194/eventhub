// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reservation_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ReservationDto _$ReservationDtoFromJson(
  Map<String, dynamic> json,
) => _ReservationDto(
  eventId: json['eventId'] as String,
  userId: json['userId'] as String,
  organizerId: json['organizerId'] as String,
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
  tierId: json['tierId'] as String?,
  tierName: json['tierName'] as String?,
  pricePaid: (json['pricePaid'] as num?)?.toInt() ?? 0,
  amountDue: (json['amountDue'] as num?)?.toInt(),
  currency: json['currency'] as String?,
  paymentStatus: json['paymentStatus'] as String?,
  checkoutUrl: json['checkoutUrl'] as String?,
  holdExpiresAt: const NullableTimestampConverter().fromJson(
    json['holdExpiresAt'],
  ),
);

Map<String, dynamic> _$ReservationDtoToJson(
  _ReservationDto instance,
) => <String, dynamic>{
  'eventId': instance.eventId,
  'userId': instance.userId,
  'organizerId': instance.organizerId,
  'userName': instance.userName,
  'userEmail': instance.userEmail,
  'eventTitle': instance.eventTitle,
  'eventStartsAt': const TimestampConverter().toJson(instance.eventStartsAt),
  'eventLocation': instance.eventLocation,
  'status': _$ReservationStatusEnumMap[instance.status]!,
  'reservedAt': const TimestampConverter().toJson(instance.reservedAt),
  'cancelledAt': const NullableTimestampConverter().toJson(
    instance.cancelledAt,
  ),
  'tierId': ?instance.tierId,
  'tierName': ?instance.tierName,
  'pricePaid': instance.pricePaid,
  'amountDue': ?instance.amountDue,
  'currency': ?instance.currency,
  'paymentStatus': ?instance.paymentStatus,
  'checkoutUrl': ?instance.checkoutUrl,
  'holdExpiresAt': ?const NullableTimestampConverter().toJson(
    instance.holdExpiresAt,
  ),
};

const _$ReservationStatusEnumMap = {
  ReservationStatus.confirmed: 'confirmed',
  ReservationStatus.pending: 'pending',
  ReservationStatus.cancelled: 'cancelled',
};
