import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventhub/core/firebase/timestamp_converter.dart';
import 'package:eventhub/features/events/domain/entities/event.dart';
import 'package:eventhub/features/events/domain/entities/event_category.dart';
import 'package:eventhub/features/events/domain/entities/event_draft.dart';
import 'package:eventhub/features/events/domain/entities/event_tier.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'event_dto.freezed.dart';
part 'event_dto.g.dart';

/// Top-level rather than static: freezed copies the `@JsonKey` annotation
/// into the generated part, where a bare static member name does not resolve.
List<EventTierDto> _tiersFromJson(Object? json) => EventDto.tiersFromMap(json);

List<String> _staffIdsFromJson(Object? json) => [
  if (json is List)
    for (final id in json)
      if (id is String && id.isNotEmpty) id,
];

/// Document `events/{eventId}`.
///
/// One document holds the whole event — ticket types included, as a map
/// `{tierId: {name, description, price, capacity, available, order}}` — so a
/// single snapshot listener renders a card, and a booking moves the event
/// counter and its type counter in the same write (the rules compare both).
/// A map rather than a list because the rules address one type by its key
/// (`tiers[tierId].available`) and a list cannot be diffed that way.
///
/// The document id is not a field: [EventDto.fromFirestore] injects it.
@freezed
abstract class EventDto with _$EventDto {
  const EventDto._();

  const factory EventDto({
    required String id,
    required String title,
    required String description,
    @JsonKey(unknownEnumValue: EventCategory.other)
    required EventCategory category,
    @TimestampConverter() required DateTime startsAt,
    required String location,

    /// With ticket types, both counters are the sums of the types: the
    /// client computes them in the write and the rules check the arithmetic.
    required int capacity,
    required int availablePlaces,
    required String organizerId,
    required String organizerName,
    String? imageUrl,

    /// Written with `serverTimestamp()`: `null` in a pending local snapshot.
    @NullableTimestampConverter() DateTime? createdAt,
    @NullableTimestampConverter() DateTime? updatedAt,

    /// `EUR`, `USD` or `MGA`; null unless a type is paid.
    String? currency,
    @JsonKey(fromJson: _tiersFromJson)
    @Default(<EventTierDto>[])
    List<EventTierDto> tiers,
    @JsonKey(fromJson: _staffIdsFromJson)
    @Default(<String>[])
    List<String> staffIds,
  }) = _EventDto;

  factory EventDto.fromJson(Map<String, dynamic> json) =>
      _$EventDtoFromJson(json);

  /// The id wins over any `id` key a hand-written document might carry.
  factory EventDto.fromFirestore(String id, Map<String, dynamic> data) =>
      EventDto.fromJson({...data, 'id': id});

  Event toDomain() => Event(
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
    staffIds: staffIds,
    tiers: [for (final tier in tiers) tier.toDomain()],
    currency: currency,
  );

  /// `{tierId: {...}}` → types in display order: `order`, then id so that
  /// equal orders (a hand-edited document) stay stable. A malformed entry is
  /// skipped rather than failing the whole event.
  static List<EventTierDto> tiersFromMap(Object? json) {
    if (json is! Map) return const [];
    final tiers =
        <EventTierDto>[
          for (final MapEntry(:key, :value) in json.entries)
            if (key is String && value is Map)
              if (EventTierDto.tryParse(key, Map<String, dynamic>.from(value))
                  case final tier?)
                tier,
        ]..sort((a, b) {
          final byOrder = a.order.compareTo(b.order);
          return byOrder != 0 ? byOrder : a.id.compareTo(b.id);
        });
    return tiers;
  }

  /// Types → the map stored on the event. `order` is rewritten from the list
  /// position so the display order is exactly the one of the form.
  static Map<String, Map<String, Object>> tiersToMap(List<EventTier> tiers) => {
    for (var i = 0; i < tiers.length; i++)
      tiers[i].id: {
        'name': tiers[i].name,
        'description': tiers[i].description,
        'price': tiers[i].price,
        'capacity': tiers[i].capacity,
        'available': tiers[i].available,
        'order': i,
      },
  };

  /// The content fields an organizer controls, shared by creation and edit.
  ///
  /// [draft] must be validated (trimmed, capacity summed). Counters and types
  /// come from the plan computed against the current document, never from
  /// the draft: the rules require `availablePlaces == capacity − taken`.
  /// `imageUrl` and `currency` are written even when null, so clearing them in
  /// the form clears them in the document.
  static Map<String, Object?> contentFields(
    EventDraft draft, {
    required int capacity,
    required int availablePlaces,
    required List<EventTier> tiers,
  }) => {
    'title': draft.title,
    'description': draft.description,
    'category': draft.category.name,
    'startsAt': Timestamp.fromDate(draft.startsAt),
    'location': draft.location,
    'capacity': capacity,
    'availablePlaces': availablePlaces,
    'imageUrl': draft.imageUrl,
    'currency': draft.currency,
    'tiers': tiersToMap(tiers),
  };

  /// A new document: the only shape `allow create` accepts — every seat
  /// free, no team yet, the organizer name copied from `users/{uid}.name`.
  static Map<String, Object?> createFields(
    EventDraft draft, {
    required String organizerId,
    required String organizerName,
    required TierPlan? plan,
  }) => {
    ...contentFields(
      draft,
      capacity: plan?.capacity ?? draft.capacity,
      availablePlaces: plan?.available ?? draft.capacity,
      tiers: plan?.tiers ?? const [],
    ),
    'organizerId': organizerId,
    'organizerName': organizerName,
    'staffIds': const <String>[],
    'createdAt': FieldValue.serverTimestamp(),
  };
}

/// One entry of `events/{id}.tiers`, keyed by [id].
@freezed
abstract class EventTierDto with _$EventTierDto {
  const EventTierDto._();

  const factory EventTierDto({
    required String id,
    required String name,
    required int capacity,
    required int available,

    /// What the type includes ("Accès backstage"), possibly empty.
    @Default('') String description,

    /// Integer minor units (cents; ariary for MGA).
    @Default(0) int price,

    /// 0..5, the display order chosen in the form.
    @Default(0) int order,
  }) = _EventTierDto;

  factory EventTierDto.fromJson(Map<String, dynamic> json) =>
      _$EventTierDtoFromJson(json);

  /// `null` when the entry lacks a required field or has the wrong type.
  static EventTierDto? tryParse(String id, Map<String, dynamic> data) {
    try {
      return EventTierDto.fromJson({...data, 'id': id});
    } on Object {
      return null;
    }
  }

  EventTier toDomain() => EventTier(
    id: id,
    name: name,
    description: description,
    capacity: capacity,
    available: available,
    price: price,
    order: order,
  );
}
