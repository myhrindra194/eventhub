import 'package:eventhub/core/supabase/timestamp_converter.dart';
import 'package:eventhub/features/reviews/domain/review.dart';
import 'package:json_annotation/json_annotation.dart';

part 'review_dto.g.dart';

/// Row of `public.reviews`. `author_id` and `author_name` are stamped by the
/// insert trigger; `author_id` becomes null when the account is deleted.
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class ReviewDto {
  const ReviewDto({
    required this.id,
    required this.eventId,
    required this.createdAt,
    this.authorId,
    this.authorName = '',
    this.rating = 0,
    this.comment = '',
    this.hidden = false,
    this.updatedAt,
  });

  factory ReviewDto.fromJson(Map<String, dynamic> json) =>
      _$ReviewDtoFromJson(json);

  final String id;
  final String eventId;
  final String? authorId;
  final String authorName;
  final int rating;
  final String comment;
  final bool hidden;
  @TimestampConverter()
  final DateTime createdAt;
  @NullableTimestampConverter()
  final DateTime? updatedAt;

  Review toDomain() => Review(
    id: id,
    eventId: eventId,
    authorId: authorId ?? '',
    authorName: authorName,
    rating: rating,
    comment: comment,
    createdAt: createdAt,
    updatedAt: updatedAt,
    hidden: hidden,
  );
}
