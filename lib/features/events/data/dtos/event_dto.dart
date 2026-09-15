import 'package:eventhub/core/supabase/timestamp_converter.dart';
import 'package:eventhub/features/events/domain/entities/event.dart';
import 'package:eventhub/features/events/domain/entities/event_category.dart';
import 'package:eventhub/features/events/domain/entities/event_draft.dart';
import 'package:eventhub/features/events/domain/entities/event_tier.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'event_dto.freezed.dart';
part 'event_dto.g.dart';

/// Top-level rather than static: freezed copies the `@JsonKey` annotation
/// into the generated part, where a bare static member name does not resolve.
List<String> _staffIdsFromJson(Object? json) => [
  if (json is List)
    for (final row in json)
      if (row is Map && row['user_id'] is String) row['user_id'] as String,
];

/// Row of `public.events`.
///
/// Realtime rows carry the columns only; one-shot reads embed the ticket
/// types and the team (`select('*, event_tiers(*), event_staff(user_id)')`),
/// which land in [tiers] and [staffIds]. Streams join the three tables
/// themselves and hand the related rows to [toDomain].
@freezed
abstract class EventDto with _$EventDto {
  const EventDto._();

  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory EventDto({
    required String id,
    required String title,
    required String description,
    @JsonKey(unknownEnumValue: EventCategory.other)
    required EventCategory category,
    @TimestampConverter() required DateTime startsAt,
    required String location,

    /// With ticket types, both counters are the sums of the types, kept by
    /// a trigger: the client never computes them.
    required int capacity,
    required int availablePlaces,
    required String organizerId,
    required String organizerName,
    String? imageUrl,
    @NullableTimestampConverter() DateTime? createdAt,
    @NullableTimestampConverter() DateTime? updatedAt,

    /// `EUR`, `USD` or `MGA`; null unless a type is paid.
    String? currency,

    /// Embedded `event_tiers`, absent from Realtime rows.
    @JsonKey(name: 'event_tiers', includeToJson: false)
    @Default(<EventTierDto>[])
    List<EventTierDto> tiers,

    /// Embedded `event_staff(user_id)`, absent from Realtime rows.
    @JsonKey(
      name: 'event_staff',
      fromJson: _staffIdsFromJson,
      includeToJson: false,
    )
    @Default(<String>[])
    List<String> staffIds,
  }) = _EventDto;

  factory EventDto.fromJson(Map<String, dynamic> json) =>
      _$EventDtoFromJson(json);

  /// [tiers] and [staffIds] replace the embedded lists when given: a stream
  /// reads them from their own tables.
  Event toDomain({List<EventTierDto>? tiers, List<String>? staffIds}) => Event(
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
    staffIds: staffIds ?? this.staffIds,
    tiers: sortedTiers(tiers ?? this.tiers),
    currency: currency,
  );

  /// Display order: `position`, then id so that equal positions (never
  /// written by `save_event`, but possible mid-edit on a stream) stay stable.
  static List<EventTier> sortedTiers(List<EventTierDto> rows) {
    final sorted = [...rows]
      ..sort((a, b) {
        final byPosition = a.position.compareTo(b.position);
        return byPosition != 0 ? byPosition : a.id.compareTo(b.id);
      });
    return [for (final row in sorted) row.toDomain()];
  }

  /// `[{user_id: ...}]` → user ids; a malformed entry is skipped.
  static List<String> staffIdsFromJson(Object? json) => _staffIdsFromJson(json);

  /// `p_event` of `save_event`: the draft as typed, nothing computed.
  ///
  /// The database owns the seat counters, the organizer name and the tier
  /// ids. A tier keeps its row (and what it sold) only when its `id` is the
  /// uuid of an existing tier; any other value creates a new one, so a
  /// client-side placeholder id is simply left out. `capacity` travels only
  /// without types: with types it is their sum.
  static Map<String, Object?> saveEventPayload(
    EventDraft draft, {
    String? eventId,
  }) => {
    'id': ?eventId,
    'title': draft.title,
    'description': draft.description,
    'category': draft.category.name,
    'starts_at': const TimestampConverter().toJson(draft.startsAt),
    'location': draft.location,
    'image_url': draft.imageUrl,
    if (draft.tiers.isEmpty) 'capacity': draft.capacity,
    'currency': ?draft.currency,
    'tiers': [
      for (final tier in draft.tiers)
        {
          if (tier.id != null && isUuid(tier.id!)) 'id': tier.id,
          'name': tier.name,
          'price': tier.price,
          'capacity': tier.capacity,
        },
    ],
  };

  static final _uuid = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  static bool isUuid(String value) => _uuid.hasMatch(value);
}

/// Row of `public.event_tiers`, read-only for clients.
@freezed
abstract class EventTierDto with _$EventTierDto {
  const EventTierDto._();

  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory EventTierDto({
    required String id,
    required String eventId,
    required String name,
    required int capacity,
    required int available,

    /// Integer minor units (cents; ariary for MGA).
    @Default(0) int price,

    /// 0..5, the display order chosen in the form.
    @Default(0) int position,
  }) = _EventTierDto;

  factory EventTierDto.fromJson(Map<String, dynamic> json) =>
      _$EventTierDtoFromJson(json);

  /// The database has no per-type description: the domain field stays
  /// empty until it does.
  EventTier toDomain() => EventTier(
    id: id,
    name: name,
    capacity: capacity,
    available: available,
    price: price,
    order: position,
  );
}
