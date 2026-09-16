// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'organizer_profile_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrganizerProfileDto _$OrganizerProfileDtoFromJson(Map<String, dynamic> json) =>
    OrganizerProfileDto(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      bio: json['bio'] as String?,
      photoUrl: json['photoUrl'] as String?,
      followerCount: (json['followerCount'] as num?)?.toInt() ?? 0,
      eventCount: (json['eventCount'] as num?)?.toInt() ?? 0,
      ratingSum: (json['ratingSum'] as num?)?.toInt() ?? 0,
      ratingCount: (json['ratingCount'] as num?)?.toInt() ?? 0,
      memberSince: const NullableTimestampConverter().fromJson(
        json['memberSince'],
      ),
    );
