import 'package:eventhub/core/firebase/timestamp_converter.dart';
import 'package:eventhub/features/reviews/domain/review.dart';
import 'package:json_annotation/json_annotation.dart';

part 'review_dto.g.dart';

/// Document `reviews/{eventId}_{authorId}` ; l’id est lu depuis le snapshot.
/// `authorId` devient `''` lorsque le compte est supprimé.
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

  /// Heure du serveur : `null` dans l’instantané local en attente de
  /// l’auteur.
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
    // Un avis tout juste écrit s’affiche immédiatement, daté de maintenant,
    // jusqu’à ce que l’heure du serveur arrive un instant plus tard.
    createdAt: createdAt ?? DateTime.now(),
    updatedAt: updatedAt,
    hidden: hidden,
  );
}
