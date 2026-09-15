import 'package:eventhub/core/firebase/timestamp_converter.dart';
import 'package:eventhub/features/reviews/domain/review.dart';
import 'package:json_annotation/json_annotation.dart';

part 'review_dto.g.dart';

/// Document `reviews/{eventId}_{authorId}`; the id is read from the
/// snapshot. `authorId` becomes `''` when the account is deleted.
@JsonSerializable(createToJson: false)
class ReviewDto {
  const ReviewDto({
    required this.eventId,
    this.organizerId = '',
    this.authorId = '',
    this.authorName = '',
    this.rating = 0,
    this.comment = '',
    this.hidden = false,
    this.createdAt,
    this.updatedAt,
  });

  factory ReviewDto.fromJson(Map<String, dynamic> json) =>
      _$ReviewDtoFromJson(json);

  final String eventId;
  final String organizerId;
  final String authorId;
  final String authorName;
  final int rating;
  final String comment;
  final bool hidden;

  /// Server time: `null` in the author's pending local snapshot.
  @NullableTimestampConverter()
  final DateTime? createdAt;
  @NullableTimestampConverter()
  final DateTime? updatedAt;

  Review toDomain(String id) => Review(
    id: id,
    eventId: eventId,
    organizerId: organizerId,
    authorId: authorId,
    authorName: authorName,
    rating: rating,
    comment: comment,
    // A review just written shows at once, dated now, until the server
    // time arrives a moment later.
    createdAt: createdAt ?? DateTime.now(),
    updatedAt: updatedAt,
    hidden: hidden,
  );
}
