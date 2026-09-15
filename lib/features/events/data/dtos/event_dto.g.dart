// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EventDto _$EventDtoFromJson(Map<String, dynamic> json) => _EventDto(
  id: json['id'] as String,
  title: json['title'] as String,
  description: json['description'] as String,
  category: $enumDecode(
    _$EventCategoryEnumMap,
    json['category'],
    unknownValue: EventCategory.other,
  ),
  startsAt: const TimestampConverter().fromJson(json['starts_at'] as Object),
  location: json['location'] as String,
  capacity: (json['capacity'] as num).toInt(),
  availablePlaces: (json['available_places'] as num).toInt(),
  organizerId: json['organizer_id'] as String,
  organizerName: json['organizer_name'] as String,
  imageUrl: json['image_url'] as String?,
  createdAt: const NullableTimestampConverter().fromJson(json['created_at']),
  updatedAt: const NullableTimestampConverter().fromJson(json['updated_at']),
  currency: json['currency'] as String?,
  tiers:
      (json['event_tiers'] as List<dynamic>?)
          ?.map((e) => EventTierDto.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <EventTierDto>[],
  staffIds: json['event_staff'] == null
      ? const <String>[]
      : _staffIdsFromJson(json['event_staff']),
);

Map<String, dynamic> _$EventDtoToJson(_EventDto instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'description': instance.description,
  'category': _$EventCategoryEnumMap[instance.category]!,
  'starts_at': const TimestampConverter().toJson(instance.startsAt),
  'location': instance.location,
  'capacity': instance.capacity,
  'available_places': instance.availablePlaces,
  'organizer_id': instance.organizerId,
  'organizer_name': instance.organizerName,
  'image_url': instance.imageUrl,
  'created_at': const NullableTimestampConverter().toJson(instance.createdAt),
  'updated_at': const NullableTimestampConverter().toJson(instance.updatedAt),
  'currency': instance.currency,
};

const _$EventCategoryEnumMap = {
  EventCategory.conference: 'conference',
  EventCategory.meetup: 'meetup',
  EventCategory.workshop: 'workshop',
  EventCategory.concert: 'concert',
  EventCategory.sport: 'sport',
  EventCategory.culture: 'culture',
  EventCategory.other: 'other',
};

_EventTierDto _$EventTierDtoFromJson(Map<String, dynamic> json) =>
    _EventTierDto(
      id: json['id'] as String,
      eventId: json['event_id'] as String,
      name: json['name'] as String,
      capacity: (json['capacity'] as num).toInt(),
      available: (json['available'] as num).toInt(),
      price: (json['price'] as num?)?.toInt() ?? 0,
      position: (json['position'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$EventTierDtoToJson(_EventTierDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'event_id': instance.eventId,
      'name': instance.name,
      'capacity': instance.capacity,
      'available': instance.available,
      'price': instance.price,
      'position': instance.position,
    };
