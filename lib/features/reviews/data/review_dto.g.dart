// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReviewDto _$ReviewDtoFromJson(Map<String, dynamic> json) => ReviewDto(
  eventId: json['eventId'] as String,
  organizerId: json['organizerId'] as String? ?? '',
  authorId: json['authorId'] as String? ?? '',
  authorName: json['authorName'] as String? ?? '',
  rating: (json['rating'] as num?)?.toInt() ?? 0,
  comment: json['comment'] as String? ?? '',
  hidden: json['hidden'] as bool? ?? false,
  createdAt: const NullableTimestampConverter().fromJson(json['createdAt']),
  updatedAt: const NullableTimestampConverter().fromJson(json['updatedAt']),
);
