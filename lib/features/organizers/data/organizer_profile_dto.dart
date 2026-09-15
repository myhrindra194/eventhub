import 'dart:math' as math;

import 'package:eventhub/core/supabase/timestamp_converter.dart';
import 'package:eventhub/features/organizers/domain/organizer_profile.dart';
import 'package:json_annotation/json_annotation.dart';

part 'organizer_profile_dto.g.dart';

/// Row of `public.organizers`: copied from the private profile and counted
/// by triggers, read-only for every client.
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class OrganizerProfileDto {
  const OrganizerProfileDto({
    required this.id,
    this.name = '',
    this.bio,
    this.followerCount = 0,
    this.eventCount = 0,
    this.ratingSum = 0,
    this.ratingCount = 0,
    this.memberSince,
  });

  factory OrganizerProfileDto.fromJson(Map<String, dynamic> json) =>
      _$OrganizerProfileDtoFromJson(json);

  final String id;
  final String name;
  final String? bio;
  final int followerCount;
  final int eventCount;
  final int ratingSum;
  final int ratingCount;
  @NullableTimestampConverter()
  final DateTime? memberSince;

  OrganizerProfile toDomain() => OrganizerProfile(
    id: id,
    name: name,
    bio: bio ?? '',
    // CHECK constraints keep the counters positive; the clamp only guards a
    // fixture or a future schema change from ever rendering "-1 abonné".
    followerCount: math.max(0, followerCount),
    eventCount: math.max(0, eventCount),
    ratingSum: math.max(0, ratingSum),
    ratingCount: math.max(0, ratingCount),
    memberSince: memberSince,
  );
}
