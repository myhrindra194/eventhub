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
      followerCount: (json['follower_count'] as num?)?.toInt() ?? 0,
      eventCount: (json['event_count'] as num?)?.toInt() ?? 0,
      ratingSum: (json['rating_sum'] as num?)?.toInt() ?? 0,
      ratingCount: (json['rating_count'] as num?)?.toInt() ?? 0,
      memberSince: const NullableTimestampConverter().fromJson(
        json['member_since'],
      ),
    );
