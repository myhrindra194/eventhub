import 'package:eventhub/core/firebase/timestamp_converter.dart';
import 'package:eventhub/features/events/domain/entities/event.dart';
import 'package:eventhub/features/events/domain/entities/event_category.dart';
import 'package:eventhub/features/events/domain/entities/event_draft.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'event_dto.freezed.dart';
part 'event_dto.g.dart';

/// Firestore document `events/{id}`.
@freezed
abstract class EventDto with _$EventDto {
  const EventDto._();

  const factory EventDto({
    required String title,
    required String description,
    @JsonKey(unknownEnumValue: EventCategory.other)
    required EventCategory category,
    @TimestampConverter() required DateTime startsAt,
    required String location,
    required int capacity,
    required int availablePlaces,
    required String organizerId,
    required String organizerName,
    String? imageUrl,
    @NullableTimestampConverter() DateTime? createdAt,
    @NullableTimestampConverter() DateTime? updatedAt,
  }) = _EventDto;

  factory EventDto.fromJson(Map<String, dynamic> json) =>
      _$EventDtoFromJson(json);

  /// New event: every seat is available.
  factory EventDto.fromDraft(
    EventDraft draft, {
    required String organizerId,
    required String organizerName,
  }) => EventDto(
    title: draft.title,
    description: draft.description,
    category: draft.category,
    startsAt: draft.startsAt,
    location: draft.location,
    capacity: draft.capacity,
    availablePlaces: draft.capacity,
    organizerId: organizerId,
    organizerName: organizerName,
    imageUrl: draft.imageUrl,
  );

  Event toDomain(String id) => Event(
    id: id,
    title: title,
    description: description,
    category: category,
    startsAt: startsAt,
    location: location,
    capacity: capacity,
    availablePlaces: availablePlaces,
    organizerId: organizerId,
    organizerName: organizerName,
    imageUrl: imageUrl,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
