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
  startsAt: const TimestampConverter().fromJson(json['startsAt'] as Object),
  location: json['location'] as String,
  capacity: (json['capacity'] as num).toInt(),
  availablePlaces: (json['availablePlaces'] as num).toInt(),
  organizerId: json['organizerId'] as String,
  organizerName: json['organizerName'] as String,
  imageUrl: json['imageUrl'] as String?,
  createdAt: const NullableTimestampConverter().fromJson(json['createdAt']),
  updatedAt: const NullableTimestampConverter().fromJson(json['updatedAt']),
  currency: json['currency'] as String?,
  tiers: json['tiers'] == null
      ? const <EventTierDto>[]
      : _tiersFromJson(json['tiers']),
  staffIds: json['staffIds'] == null
      ? const <String>[]
      : _staffIdsFromJson(json['staffIds']),
);

Map<String, dynamic> _$EventDtoToJson(_EventDto instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'description': instance.description,
  'category': _$EventCategoryEnumMap[instance.category]!,
  'startsAt': const TimestampConverter().toJson(instance.startsAt),
  'location': instance.location,
  'capacity': instance.capacity,
  'availablePlaces': instance.availablePlaces,
  'organizerId': instance.organizerId,
  'organizerName': instance.organizerName,
  'imageUrl': instance.imageUrl,
  'createdAt': const NullableTimestampConverter().toJson(instance.createdAt),
  'updatedAt': const NullableTimestampConverter().toJson(instance.updatedAt),
  'currency': instance.currency,
  'tiers': instance.tiers,
  'staffIds': instance.staffIds,
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
      name: json['name'] as String,
      capacity: (json['capacity'] as num).toInt(),
      available: (json['available'] as num).toInt(),
      description: json['description'] as String? ?? '',
      price: (json['price'] as num?)?.toInt() ?? 0,
      order: (json['order'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$EventTierDtoToJson(_EventTierDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'capacity': instance.capacity,
      'available': instance.available,
      'description': instance.description,
      'price': instance.price,
      'order': instance.order,
    };
