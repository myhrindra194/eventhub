import 'package:eventhub/core/firebase/timestamp_converter.dart';
import 'package:eventhub/features/events/domain/entities/event.dart';
import 'package:eventhub/features/events/domain/entities/event_category.dart';
import 'package:eventhub/features/events/domain/entities/event_draft.dart';
import 'package:eventhub/features/events/domain/entities/event_tier.dart';
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

    /// Written by Cloud Functions only; a new event is created with `[]`.
    @Default(<String>[]) List<String> staffIds,

    /// `tiers.{id} = {name, description, price, capacity, available, order}`.
    @Default(<String, dynamic>{}) Map<String, dynamic> tiers,

    /// Omitted when null: the rules only accept a known currency code.
    @JsonKey(includeIfNull: false) String? currency,
  }) = _EventDto;

  factory EventDto.fromJson(Map<String, dynamic> json) =>
      _$EventDtoFromJson(json);

  /// New event: every seat of every type is available.
  factory EventDto.fromDraft(
    EventDraft draft, {
    required String organizerId,
    required String organizerName,
    String Function()? tierIds,
  }) {
    final plan = draft.tiers.isEmpty
        ? null
        : TierPlanner.initial(draft.tiers, ids: tierIds);
    return EventDto(
      title: draft.title,
      description: draft.description,
      category: draft.category,
      startsAt: draft.startsAt,
      location: draft.location,
      capacity: plan?.capacity ?? draft.capacity,
      availablePlaces: plan?.available ?? draft.capacity,
      organizerId: organizerId,
      organizerName: organizerName,
      imageUrl: draft.imageUrl,
      tiers: plan == null ? const {} : tiersToMap(plan.tiers),
      currency: (plan?.hasPaid ?? false) ? draft.currency : null,
    );
  }

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
    staffIds: staffIds,
    tiers: tiersFromMap(tiers),
    currency: currency,
  );

  /// Tolerant reader: a malformed entry is skipped rather than thrown on,
  /// types are sorted by `order` then id.
  static List<EventTier> tiersFromMap(Map<String, dynamic> raw) {
    int number(Object? value) => (value as num?)?.toInt() ?? 0;
    final list =
        <EventTier>[
          for (final entry in raw.entries)
            if (entry.value is Map && EventTier.isValidId(entry.key))
              EventTier(
                id: entry.key,
                name: (entry.value as Map)['name'] as String? ?? '',
                description:
                    (entry.value as Map)['description'] as String? ?? '',
                price: number((entry.value as Map)['price']),
                capacity: number((entry.value as Map)['capacity']),
                available: number((entry.value as Map)['available']),
                order: number((entry.value as Map)['order']),
              ),
        ]..sort((a, b) {
          final byOrder = a.order.compareTo(b.order);
          return byOrder != 0 ? byOrder : a.id.compareTo(b.id);
        });
    return list;
  }

  static Map<String, Object?> tiersToMap(List<EventTier> tiers) => {
    for (final t in tiers)
      t.id: {
        'name': t.name,
        'description': t.description,
        'price': t.price,
        'capacity': t.capacity,
        'available': t.available,
        'order': t.order,
      },
  };
}
