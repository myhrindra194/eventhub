import 'package:eventhub/core/supabase/timestamp_converter.dart';
import 'package:eventhub/features/notifications/domain/app_notification.dart';
import 'package:eventhub/features/notifications/domain/notification_preferences.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_dto.freezed.dart';
part 'notification_dto.g.dart';

/// Row of `public.notifications`, written by the database (`private.notify`)
/// and read by its owner through PostgREST or Realtime.
///
/// `type` stays a plain string: the Postgres enum `notification_type` uses
/// the exact names of `NotificationRoute`, and a value added server-side
/// before the app is updated must still render (it simply opens nothing).
@freezed
abstract class NotificationDto with _$NotificationDto {
  const NotificationDto._();

  const factory NotificationDto({
    required String id,
    required String type,
    @Default('') String title,
    @Default('') String body,
    @JsonKey(name: 'event_id') String? eventId,
    @JsonKey(name: 'reservation_id') String? reservationId,
    @JsonKey(name: 'created_at')
    @TimestampConverter()
    required DateTime createdAt,
    @JsonKey(name: 'read_at') @NullableTimestampConverter() DateTime? readAt,

    /// Purged by pg_cron after 30 days; filtered client-side in between so
    /// a row past its date never shows while the purge has not run yet.
    @JsonKey(name: 'expires_at')
    @NullableTimestampConverter()
    DateTime? expiresAt,
  }) = _NotificationDto;

  factory NotificationDto.fromJson(Map<String, dynamic> json) =>
      _$NotificationDtoFromJson(json);

  AppNotification toDomain() => AppNotification(
    id: id,
    type: type,
    title: title,
    body: body,
    createdAt: createdAt,
    eventId: eventId,
    reservationId: reservationId,
    readAt: readAt,
  );
}

/// Row of `public.notification_preferences`, created with the profile by a
/// trigger. Only these three columns are granted for update; `updated_at` is
/// stamped by the database, so it is never sent.
@freezed
abstract class NotificationPreferencesDto with _$NotificationPreferencesDto {
  const NotificationPreferencesDto._();

  const factory NotificationPreferencesDto({
    @JsonKey(name: 'event_reminders') @Default(true) bool eventReminders,
    @JsonKey(name: 'booking_alerts') @Default(true) bool bookingAlerts,
    @JsonKey(name: 'followed_organizers')
    @Default(true)
    bool followedOrganizers,
  }) = _NotificationPreferencesDto;

  factory NotificationPreferencesDto.fromJson(Map<String, dynamic> json) =>
      _$NotificationPreferencesDtoFromJson(json);

  factory NotificationPreferencesDto.fromDomain(NotificationPreferences p) =>
      NotificationPreferencesDto(
        eventReminders: p.eventReminders,
        bookingAlerts: p.bookingAlerts,
        followedOrganizers: p.followedOrganizers,
      );

  NotificationPreferences toDomain() => NotificationPreferences(
    eventReminders: eventReminders,
    bookingAlerts: bookingAlerts,
    followedOrganizers: followedOrganizers,
  );
}
