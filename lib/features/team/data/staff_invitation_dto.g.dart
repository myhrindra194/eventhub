// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staff_invitation_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StaffInvitationDto _$StaffInvitationDtoFromJson(Map<String, dynamic> json) =>
    StaffInvitationDto(
      eventId: json['eventId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '',
      invitedByName: json['invitedByName'] as String? ?? '',
      eventTitle: json['eventTitle'] as String? ?? '',
      eventStartsAt: const NullableTimestampConverter().fromJson(
        json['eventStartsAt'],
      ),
      status: json['status'] as String?,
      createdAt: const NullableTimestampConverter().fromJson(json['createdAt']),
    );
