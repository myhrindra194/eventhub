// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staff_invitation_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StaffInvitationDto _$StaffInvitationDtoFromJson(Map<String, dynamic> json) =>
    StaffInvitationDto(
      eventId: json['event_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '',
      invitedByName: json['invited_by_name'] as String? ?? '',
      eventTitle: json['event_title'] as String? ?? '',
      eventStartsAt: const NullableTimestampConverter().fromJson(
        json['event_starts_at'],
      ),
      status: json['status'] as String?,
      createdAt: const NullableTimestampConverter().fromJson(
        json['created_at'],
      ),
    );
