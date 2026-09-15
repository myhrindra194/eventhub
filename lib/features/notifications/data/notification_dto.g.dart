// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NotificationDto _$NotificationDtoFromJson(
  Map<String, dynamic> json,
) => _NotificationDto(
  id: json['id'] as String,
  type: json['type'] as String,
  title: json['title'] as String? ?? '',
  body: json['body'] as String? ?? '',
  eventId: json['event_id'] as String?,
  reservationId: json['reservation_id'] as String?,
  createdAt: const TimestampConverter().fromJson(json['created_at'] as Object),
  readAt: const NullableTimestampConverter().fromJson(json['read_at']),
  expiresAt: const NullableTimestampConverter().fromJson(json['expires_at']),
);

Map<String, dynamic> _$NotificationDtoToJson(
  _NotificationDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'type': instance.type,
  'title': instance.title,
  'body': instance.body,
  'event_id': instance.eventId,
  'reservation_id': instance.reservationId,
  'created_at': const TimestampConverter().toJson(instance.createdAt),
  'read_at': const NullableTimestampConverter().toJson(instance.readAt),
  'expires_at': const NullableTimestampConverter().toJson(instance.expiresAt),
};

_NotificationPreferencesDto _$NotificationPreferencesDtoFromJson(
  Map<String, dynamic> json,
) => _NotificationPreferencesDto(
  eventReminders: json['event_reminders'] as bool? ?? true,
  bookingAlerts: json['booking_alerts'] as bool? ?? true,
  followedOrganizers: json['followed_organizers'] as bool? ?? true,
);

Map<String, dynamic> _$NotificationPreferencesDtoToJson(
  _NotificationPreferencesDto instance,
) => <String, dynamic>{
  'event_reminders': instance.eventReminders,
  'booking_alerts': instance.bookingAlerts,
  'followed_organizers': instance.followedOrganizers,
};
