// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reservation_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ReservationDto _$ReservationDtoFromJson(Map<String, dynamic> json) =>
    _ReservationDto(
      id: json['id'] as String,
      eventId: json['event_id'] as String?,
      userId: json['user_id'] as String?,
      organizerId: json['organizer_id'] as String?,
      userName: json['user_name'] as String,
      userEmail: json['user_email'] as String,
      eventTitle: json['event_title'] as String,
      eventStartsAt: const TimestampConverter().fromJson(
        json['event_starts_at'] as Object,
      ),
      eventLocation: json['event_location'] as String,
      status: $enumDecode(
        _$ReservationStatusEnumMap,
        json['status'],
        unknownValue: ReservationStatus.cancelled,
      ),
      reservedAt: const TimestampConverter().fromJson(
        json['reserved_at'] as Object,
      ),
      cancelledAt: const NullableTimestampConverter().fromJson(
        json['cancelled_at'],
      ),
      tierId: json['tier_id'] as String?,
      tierName: json['tier_name'] as String?,
      pricePaid: (json['price_paid'] as num?)?.toInt() ?? 0,
      amountDue: (json['amount_due'] as num?)?.toInt(),
      currency: json['currency'] as String?,
      paymentStatus: json['payment_status'] as String?,
      checkoutUrl: json['checkout_url'] as String?,
      holdExpiresAt: const NullableTimestampConverter().fromJson(
        json['hold_expires_at'],
      ),
    );

const _$ReservationStatusEnumMap = {
  ReservationStatus.confirmed: 'confirmed',
  ReservationStatus.pending: 'pending',
  ReservationStatus.cancelled: 'cancelled',
};
