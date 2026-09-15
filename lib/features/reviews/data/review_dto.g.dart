// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReviewDto _$ReviewDtoFromJson(Map<String, dynamic> json) => ReviewDto(
  id: json['id'] as String,
  eventId: json['event_id'] as String,
  createdAt: const TimestampConverter().fromJson(json['created_at'] as Object),
  authorId: json['author_id'] as String?,
  authorName: json['author_name'] as String? ?? '',
  rating: (json['rating'] as num?)?.toInt() ?? 0,
  comment: json['comment'] as String? ?? '',
  hidden: json['hidden'] as bool? ?? false,
  updatedAt: const NullableTimestampConverter().fromJson(json['updated_at']),
);
