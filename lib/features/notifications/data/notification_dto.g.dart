// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NotificationDto _$NotificationDtoFromJson(Map<String, dynamic> json) =>
    _NotificationDto(
      type: json['type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      eventId: json['eventId'] as String?,
      reservationId: json['reservationId'] as String?,
      createdAt: const NullableTimestampConverter().fromJson(json['createdAt']),
      readAt: const NullableTimestampConverter().fromJson(json['readAt']),
      expiresAt: const NullableTimestampConverter().fromJson(json['expiresAt']),
    );

Map<String, dynamic> _$NotificationDtoToJson(
  _NotificationDto instance,
) => <String, dynamic>{
  'type': instance.type,
  'title': instance.title,
  'body': instance.body,
  'eventId': instance.eventId,
  'reservationId': instance.reservationId,
  'createdAt': const NullableTimestampConverter().toJson(instance.createdAt),
  'readAt': const NullableTimestampConverter().toJson(instance.readAt),
  'expiresAt': const NullableTimestampConverter().toJson(instance.expiresAt),
};
