// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'event_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EventDto {

 String get id; String get title; String get description;@JsonKey(unknownEnumValue: EventCategory.other) EventCategory get category;@TimestampConverter() DateTime get startsAt; String get location;/// With ticket types, both counters are the sums of the types, kept by
/// a trigger: the client never computes them.
 int get capacity; int get availablePlaces; String get organizerId; String get organizerName; String? get imageUrl;@NullableTimestampConverter() DateTime? get createdAt;@NullableTimestampConverter() DateTime? get updatedAt;/// `EUR`, `USD` or `MGA`; null unless a type is paid.
 String? get currency;/// Embedded `event_tiers`, absent from Realtime rows.
@JsonKey(name: 'event_tiers', includeToJson: false) List<EventTierDto> get tiers;/// Embedded `event_staff(user_id)`, absent from Realtime rows.
@JsonKey(name: 'event_staff', fromJson: _staffIdsFromJson, includeToJson: false) List<String> get staffIds;
/// Create a copy of EventDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EventDtoCopyWith<EventDto> get copyWith => _$EventDtoCopyWithImpl<EventDto>(this as EventDto, _$identity);

  /// Serializes this EventDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as EventDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EventDto&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.category, _this.category) || other.category == _this.category)&&(identical(other.startsAt, _this.startsAt) || other.startsAt == _this.startsAt)&&(identical(other.location, _this.location) || other.location == _this.location)&&(identical(other.capacity, _this.capacity) || other.capacity == _this.capacity)&&(identical(other.availablePlaces, _this.availablePlaces) || other.availablePlaces == _this.availablePlaces)&&(identical(other.organizerId, _this.organizerId) || other.organizerId == _this.organizerId)&&(identical(other.organizerName, _this.organizerName) || other.organizerName == _this.organizerName)&&(identical(other.imageUrl, _this.imageUrl) || other.imageUrl == _this.imageUrl)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt)&&(identical(other.currency, _this.currency) || other.currency == _this.currency)&&const DeepCollectionEquality().equals(other.tiers, _this.tiers)&&const DeepCollectionEquality().equals(other.staffIds, _this.staffIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as EventDto;
  return Object.hash(runtimeType,_this.id,_this.title,_this.description,_this.category,_this.startsAt,_this.location,_this.capacity,_this.availablePlaces,_this.organizerId,_this.organizerName,_this.imageUrl,_this.createdAt,_this.updatedAt,_this.currency,const DeepCollectionEquality().hash(_this.tiers),const DeepCollectionEquality().hash(_this.staffIds));
}

@override
String toString() {
  final _this = this as EventDto;
  return 'EventDto(id: ${_this.id}, title: ${_this.title}, description: ${_this.description}, category: ${_this.category}, startsAt: ${_this.startsAt}, location: ${_this.location}, capacity: ${_this.capacity}, availablePlaces: ${_this.availablePlaces}, organizerId: ${_this.organizerId}, organizerName: ${_this.organizerName}, imageUrl: ${_this.imageUrl}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt}, currency: ${_this.currency}, tiers: ${_this.tiers}, staffIds: ${_this.staffIds})';
}


}

/// @nodoc
abstract mixin class $EventDtoCopyWith<$Res>  {
  factory $EventDtoCopyWith(EventDto value, $Res Function(EventDto) _then) = _$EventDtoCopyWithImpl;
@useResult
$Res call({
 String id, String title, String description,@JsonKey(unknownEnumValue: EventCategory.other) EventCategory category,@TimestampConverter() DateTime startsAt, String location, int capacity, int availablePlaces, String organizerId, String organizerName, String? imageUrl,@NullableTimestampConverter() DateTime? createdAt,@NullableTimestampConverter() DateTime? updatedAt, String? currency,@JsonKey(name: 'event_tiers', includeToJson: false) List<EventTierDto> tiers,@JsonKey(name: 'event_staff', fromJson: _staffIdsFromJson, includeToJson: false) List<String> staffIds
});




}
/// @nodoc
class _$EventDtoCopyWithImpl<$Res>
    implements $EventDtoCopyWith<$Res> {
  _$EventDtoCopyWithImpl(this._self, this._then);

  final EventDto _self;
  final $Res Function(EventDto) _then;

/// Create a copy of EventDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? description = null,Object? category = null,Object? startsAt = null,Object? location = null,Object? capacity = null,Object? availablePlaces = null,Object? organizerId = null,Object? organizerName = null,Object? imageUrl = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? currency = freezed,Object? tiers = null,Object? staffIds = null,}) {
  return _then(EventDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as EventCategory,startsAt: null == startsAt ? _self.startsAt : startsAt // ignore: cast_nullable_to_non_nullable
as DateTime,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String,capacity: null == capacity ? _self.capacity : capacity // ignore: cast_nullable_to_non_nullable
as int,availablePlaces: null == availablePlaces ? _self.availablePlaces : availablePlaces // ignore: cast_nullable_to_non_nullable
as int,organizerId: null == organizerId ? _self.organizerId : organizerId // ignore: cast_nullable_to_non_nullable
as String,organizerName: null == organizerName ? _self.organizerName : organizerName // ignore: cast_nullable_to_non_nullable
as String,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,currency: freezed == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String?,tiers: null == tiers ? _self.tiers : tiers // ignore: cast_nullable_to_non_nullable
as List<EventTierDto>,staffIds: null == staffIds ? _self.staffIds : staffIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [EventDto].
extension EventDtoPatterns on EventDto {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EventDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EventDto() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EventDto value)  $default,){
final _that = this;
switch (_that) {
case _EventDto():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EventDto value)?  $default,){
final _that = this;
switch (_that) {
case _EventDto() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String description, @JsonKey(unknownEnumValue: EventCategory.other)  EventCategory category, @TimestampConverter()  DateTime startsAt,  String location,  int capacity,  int availablePlaces,  String organizerId,  String organizerName,  String? imageUrl, @NullableTimestampConverter()  DateTime? createdAt, @NullableTimestampConverter()  DateTime? updatedAt,  String? currency, @JsonKey(name: 'event_tiers', includeToJson: false)  List<EventTierDto> tiers, @JsonKey(name: 'event_staff', fromJson: _staffIdsFromJson, includeToJson: false)  List<String> staffIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EventDto() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.category,_that.startsAt,_that.location,_that.capacity,_that.availablePlaces,_that.organizerId,_that.organizerName,_that.imageUrl,_that.createdAt,_that.updatedAt,_that.currency,_that.tiers,_that.staffIds);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String description, @JsonKey(unknownEnumValue: EventCategory.other)  EventCategory category, @TimestampConverter()  DateTime startsAt,  String location,  int capacity,  int availablePlaces,  String organizerId,  String organizerName,  String? imageUrl, @NullableTimestampConverter()  DateTime? createdAt, @NullableTimestampConverter()  DateTime? updatedAt,  String? currency, @JsonKey(name: 'event_tiers', includeToJson: false)  List<EventTierDto> tiers, @JsonKey(name: 'event_staff', fromJson: _staffIdsFromJson, includeToJson: false)  List<String> staffIds)  $default,) {final _that = this;
switch (_that) {
case _EventDto():
return $default(_that.id,_that.title,_that.description,_that.category,_that.startsAt,_that.location,_that.capacity,_that.availablePlaces,_that.organizerId,_that.organizerName,_that.imageUrl,_that.createdAt,_that.updatedAt,_that.currency,_that.tiers,_that.staffIds);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String description, @JsonKey(unknownEnumValue: EventCategory.other)  EventCategory category, @TimestampConverter()  DateTime startsAt,  String location,  int capacity,  int availablePlaces,  String organizerId,  String organizerName,  String? imageUrl, @NullableTimestampConverter()  DateTime? createdAt, @NullableTimestampConverter()  DateTime? updatedAt,  String? currency, @JsonKey(name: 'event_tiers', includeToJson: false)  List<EventTierDto> tiers, @JsonKey(name: 'event_staff', fromJson: _staffIdsFromJson, includeToJson: false)  List<String> staffIds)?  $default,) {final _that = this;
switch (_that) {
case _EventDto() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.category,_that.startsAt,_that.location,_that.capacity,_that.availablePlaces,_that.organizerId,_that.organizerName,_that.imageUrl,_that.createdAt,_that.updatedAt,_that.currency,_that.tiers,_that.staffIds);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _EventDto extends EventDto {
  const _EventDto({required this.id, required this.title, required this.description, @JsonKey(unknownEnumValue: EventCategory.other) required this.category, @TimestampConverter() required this.startsAt, required this.location, required this.capacity, required this.availablePlaces, required this.organizerId, required this.organizerName, this.imageUrl, @NullableTimestampConverter() this.createdAt, @NullableTimestampConverter() this.updatedAt, this.currency, @JsonKey(name: 'event_tiers', includeToJson: false)  List<EventTierDto> tiers = const <EventTierDto>[], @JsonKey(name: 'event_staff', fromJson: _staffIdsFromJson, includeToJson: false)  List<String> staffIds = const <String>[]}): _tiers = tiers,_staffIds = staffIds,super._();
  factory _EventDto.fromJson(Map<String, dynamic> json) => _$EventDtoFromJson(json);

@override final  String id;
@override final  String title;
@override final  String description;
@override@JsonKey(unknownEnumValue: EventCategory.other) final  EventCategory category;
@override@TimestampConverter() final  DateTime startsAt;
@override final  String location;
/// With ticket types, both counters are the sums of the types, kept by
/// a trigger: the client never computes them.
@override final  int capacity;
@override final  int availablePlaces;
@override final  String organizerId;
@override final  String organizerName;
@override final  String? imageUrl;
@override@NullableTimestampConverter() final  DateTime? createdAt;
@override@NullableTimestampConverter() final  DateTime? updatedAt;
/// `EUR`, `USD` or `MGA`; null unless a type is paid.
@override final  String? currency;
/// Embedded `event_tiers`, absent from Realtime rows.
 final  List<EventTierDto> _tiers;
/// Embedded `event_tiers`, absent from Realtime rows.
@override@JsonKey(name: 'event_tiers', includeToJson: false) List<EventTierDto> get tiers {
  if (_tiers is EqualUnmodifiableListView) return _tiers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tiers);
}

/// Embedded `event_staff(user_id)`, absent from Realtime rows.
 final  List<String> _staffIds;
/// Embedded `event_staff(user_id)`, absent from Realtime rows.
@override@JsonKey(name: 'event_staff', fromJson: _staffIdsFromJson, includeToJson: false) List<String> get staffIds {
  if (_staffIds is EqualUnmodifiableListView) return _staffIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_staffIds);
}


/// Create a copy of EventDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EventDtoCopyWith<_EventDto> get copyWith => __$EventDtoCopyWithImpl<_EventDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EventDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _EventDto&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.category, category) || other.category == category)&&(identical(other.startsAt, startsAt) || other.startsAt == startsAt)&&(identical(other.location, location) || other.location == location)&&(identical(other.capacity, capacity) || other.capacity == capacity)&&(identical(other.availablePlaces, availablePlaces) || other.availablePlaces == availablePlaces)&&(identical(other.organizerId, organizerId) || other.organizerId == organizerId)&&(identical(other.organizerName, organizerName) || other.organizerName == organizerName)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.currency, currency) || other.currency == currency)&&const DeepCollectionEquality().equals(other.tiers, _tiers)&&const DeepCollectionEquality().equals(other.staffIds, _staffIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,title,description,category,startsAt,location,capacity,availablePlaces,organizerId,organizerName,imageUrl,createdAt,updatedAt,currency,const DeepCollectionEquality().hash(_tiers),const DeepCollectionEquality().hash(_staffIds));
}

@override
String toString() {
    return 'EventDto(id: $id, title: $title, description: $description, category: $category, startsAt: $startsAt, location: $location, capacity: $capacity, availablePlaces: $availablePlaces, organizerId: $organizerId, organizerName: $organizerName, imageUrl: $imageUrl, createdAt: $createdAt, updatedAt: $updatedAt, currency: $currency, tiers: $tiers, staffIds: $staffIds)';
}


}

/// @nodoc
abstract mixin class _$EventDtoCopyWith<$Res> implements $EventDtoCopyWith<$Res> {
  factory _$EventDtoCopyWith(_EventDto value, $Res Function(_EventDto) _then) = __$EventDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String description,@JsonKey(unknownEnumValue: EventCategory.other) EventCategory category,@TimestampConverter() DateTime startsAt, String location, int capacity, int availablePlaces, String organizerId, String organizerName, String? imageUrl,@NullableTimestampConverter() DateTime? createdAt,@NullableTimestampConverter() DateTime? updatedAt, String? currency,@JsonKey(name: 'event_tiers', includeToJson: false) List<EventTierDto> tiers,@JsonKey(name: 'event_staff', fromJson: _staffIdsFromJson, includeToJson: false) List<String> staffIds
});




}
/// @nodoc
class __$EventDtoCopyWithImpl<$Res>
    implements _$EventDtoCopyWith<$Res> {
  __$EventDtoCopyWithImpl(this._self, this._then);

  final _EventDto _self;
  final $Res Function(_EventDto) _then;

/// Create a copy of EventDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? description = null,Object? category = null,Object? startsAt = null,Object? location = null,Object? capacity = null,Object? availablePlaces = null,Object? organizerId = null,Object? organizerName = null,Object? imageUrl = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? currency = freezed,Object? tiers = null,Object? staffIds = null,}) {
  return _then(_EventDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as EventCategory,startsAt: null == startsAt ? _self.startsAt : startsAt // ignore: cast_nullable_to_non_nullable
as DateTime,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String,capacity: null == capacity ? _self.capacity : capacity // ignore: cast_nullable_to_non_nullable
as int,availablePlaces: null == availablePlaces ? _self.availablePlaces : availablePlaces // ignore: cast_nullable_to_non_nullable
as int,organizerId: null == organizerId ? _self.organizerId : organizerId // ignore: cast_nullable_to_non_nullable
as String,organizerName: null == organizerName ? _self.organizerName : organizerName // ignore: cast_nullable_to_non_nullable
as String,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,currency: freezed == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String?,tiers: null == tiers ? _self._tiers : tiers // ignore: cast_nullable_to_non_nullable
as List<EventTierDto>,staffIds: null == staffIds ? _self._staffIds : staffIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}


/// @nodoc
mixin _$EventTierDto {

 String get id; String get eventId; String get name; int get capacity; int get available;/// Integer minor units (cents; ariary for MGA).
 int get price;/// 0..5, the display order chosen in the form.
 int get position;
/// Create a copy of EventTierDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EventTierDtoCopyWith<EventTierDto> get copyWith => _$EventTierDtoCopyWithImpl<EventTierDto>(this as EventTierDto, _$identity);

  /// Serializes this EventTierDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as EventTierDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EventTierDto&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.eventId, _this.eventId) || other.eventId == _this.eventId)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.capacity, _this.capacity) || other.capacity == _this.capacity)&&(identical(other.available, _this.available) || other.available == _this.available)&&(identical(other.price, _this.price) || other.price == _this.price)&&(identical(other.position, _this.position) || other.position == _this.position));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as EventTierDto;
  return Object.hash(runtimeType,_this.id,_this.eventId,_this.name,_this.capacity,_this.available,_this.price,_this.position);
}

@override
String toString() {
  final _this = this as EventTierDto;
  return 'EventTierDto(id: ${_this.id}, eventId: ${_this.eventId}, name: ${_this.name}, capacity: ${_this.capacity}, available: ${_this.available}, price: ${_this.price}, position: ${_this.position})';
}


}

/// @nodoc
abstract mixin class $EventTierDtoCopyWith<$Res>  {
  factory $EventTierDtoCopyWith(EventTierDto value, $Res Function(EventTierDto) _then) = _$EventTierDtoCopyWithImpl;
@useResult
$Res call({
 String id, String eventId, String name, int capacity, int available, int price, int position
});




}
/// @nodoc
class _$EventTierDtoCopyWithImpl<$Res>
    implements $EventTierDtoCopyWith<$Res> {
  _$EventTierDtoCopyWithImpl(this._self, this._then);

  final EventTierDto _self;
  final $Res Function(EventTierDto) _then;

/// Create a copy of EventTierDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? eventId = null,Object? name = null,Object? capacity = null,Object? available = null,Object? price = null,Object? position = null,}) {
  return _then(EventTierDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,capacity: null == capacity ? _self.capacity : capacity // ignore: cast_nullable_to_non_nullable
as int,available: null == available ? _self.available : available // ignore: cast_nullable_to_non_nullable
as int,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as int,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [EventTierDto].
extension EventTierDtoPatterns on EventTierDto {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EventTierDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EventTierDto() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EventTierDto value)  $default,){
final _that = this;
switch (_that) {
case _EventTierDto():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EventTierDto value)?  $default,){
final _that = this;
switch (_that) {
case _EventTierDto() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String eventId,  String name,  int capacity,  int available,  int price,  int position)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EventTierDto() when $default != null:
return $default(_that.id,_that.eventId,_that.name,_that.capacity,_that.available,_that.price,_that.position);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String eventId,  String name,  int capacity,  int available,  int price,  int position)  $default,) {final _that = this;
switch (_that) {
case _EventTierDto():
return $default(_that.id,_that.eventId,_that.name,_that.capacity,_that.available,_that.price,_that.position);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String eventId,  String name,  int capacity,  int available,  int price,  int position)?  $default,) {final _that = this;
switch (_that) {
case _EventTierDto() when $default != null:
return $default(_that.id,_that.eventId,_that.name,_that.capacity,_that.available,_that.price,_that.position);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _EventTierDto extends EventTierDto {
  const _EventTierDto({required this.id, required this.eventId, required this.name, required this.capacity, required this.available, this.price = 0, this.position = 0}): super._();
  factory _EventTierDto.fromJson(Map<String, dynamic> json) => _$EventTierDtoFromJson(json);

@override final  String id;
@override final  String eventId;
@override final  String name;
@override final  int capacity;
@override final  int available;
/// Integer minor units (cents; ariary for MGA).
@override@JsonKey() final  int price;
/// 0..5, the display order chosen in the form.
@override@JsonKey() final  int position;

/// Create a copy of EventTierDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EventTierDtoCopyWith<_EventTierDto> get copyWith => __$EventTierDtoCopyWithImpl<_EventTierDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EventTierDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _EventTierDto&&(identical(other.id, id) || other.id == id)&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.name, name) || other.name == name)&&(identical(other.capacity, capacity) || other.capacity == capacity)&&(identical(other.available, available) || other.available == available)&&(identical(other.price, price) || other.price == price)&&(identical(other.position, position) || other.position == position));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,eventId,name,capacity,available,price,position);
}

@override
String toString() {
    return 'EventTierDto(id: $id, eventId: $eventId, name: $name, capacity: $capacity, available: $available, price: $price, position: $position)';
}


}

/// @nodoc
abstract mixin class _$EventTierDtoCopyWith<$Res> implements $EventTierDtoCopyWith<$Res> {
  factory _$EventTierDtoCopyWith(_EventTierDto value, $Res Function(_EventTierDto) _then) = __$EventTierDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String eventId, String name, int capacity, int available, int price, int position
});




}
/// @nodoc
class __$EventTierDtoCopyWithImpl<$Res>
    implements _$EventTierDtoCopyWith<$Res> {
  __$EventTierDtoCopyWithImpl(this._self, this._then);

  final _EventTierDto _self;
  final $Res Function(_EventTierDto) _then;

/// Create a copy of EventTierDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? eventId = null,Object? name = null,Object? capacity = null,Object? available = null,Object? price = null,Object? position = null,}) {
  return _then(_EventTierDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,capacity: null == capacity ? _self.capacity : capacity // ignore: cast_nullable_to_non_nullable
as int,available: null == available ? _self.available : available // ignore: cast_nullable_to_non_nullable
as int,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as int,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
