import 'dart:math' as math;

import 'package:eventhub/core/firebase/timestamp_converter.dart';
import 'package:eventhub/features/organizers/domain/organizer_profile.dart';
import 'package:json_annotation/json_annotation.dart';

part 'organizer_profile_dto.g.dart';

/// Document `organizers/{uid}`: the public page, created by "Devenir
/// organisateur". Its counters are written by clients, but only inside the
/// batch that proves them (a follow, a published event, a review), so the
/// rules keep them honest. The document id is injected by
/// [OrganizerProfileDto.fromFirestore].
@JsonSerializable(createToJson: false)
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

  factory OrganizerProfileDto.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) => OrganizerProfileDto.fromJson({...data, 'id': id});

  final String id;
  final String name;
  final String? bio;
  final int followerCount;
  final int eventCount;
  final int ratingSum;
  final int ratingCount;

  /// Written with `serverTimestamp()`: `null` in a pending local snapshot.
  @NullableTimestampConverter()
  final DateTime? memberSince;

  OrganizerProfile toDomain() => OrganizerProfile(
    id: id,
    name: name,
    bio: bio ?? '',
    // The rules move counters by ±1 only; the clamp guards a hand-edited
    // document from ever rendering "-1 abonné".
    followerCount: math.max(0, followerCount),
    eventCount: math.max(0, eventCount),
    ratingSum: math.max(0, ratingSum),
    ratingCount: math.max(0, ratingCount),
    memberSince: memberSince,
  );
}
