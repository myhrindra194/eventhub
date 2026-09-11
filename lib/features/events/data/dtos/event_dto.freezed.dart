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

 String get title; String get description;@JsonKey(unknownEnumValue: EventCategory.other) EventCategory get category;@TimestampConverter() DateTime get startsAt; String get location; int get capacity; int get availablePlaces; String get organizerId; String get organizerName; String? get imageUrl;@NullableTimestampConverter() DateTime? get createdAt;@NullableTimestampConverter() DateTime? get updatedAt;
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EventDto&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.category, _this.category) || other.category == _this.category)&&(identical(other.startsAt, _this.startsAt) || other.startsAt == _this.startsAt)&&(identical(other.location, _this.location) || other.location == _this.location)&&(identical(other.capacity, _this.capacity) || other.capacity == _this.capacity)&&(identical(other.availablePlaces, _this.availablePlaces) || other.availablePlaces == _this.availablePlaces)&&(identical(other.organizerId, _this.organizerId) || other.organizerId == _this.organizerId)&&(identical(other.organizerName, _this.organizerName) || other.organizerName == _this.organizerName)&&(identical(other.imageUrl, _this.imageUrl) || other.imageUrl == _this.imageUrl)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as EventDto;
  return Object.hash(runtimeType,_this.title,_this.description,_this.category,_this.startsAt,_this.location,_this.capacity,_this.availablePlaces,_this.organizerId,_this.organizerName,_this.imageUrl,_this.createdAt,_this.updatedAt);
}

@override
String toString() {
  final _this = this as EventDto;
  return 'EventDto(title: ${_this.title}, description: ${_this.description}, category: ${_this.category}, startsAt: ${_this.startsAt}, location: ${_this.location}, capacity: ${_this.capacity}, availablePlaces: ${_this.availablePlaces}, organizerId: ${_this.organizerId}, organizerName: ${_this.organizerName}, imageUrl: ${_this.imageUrl}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $EventDtoCopyWith<$Res>  {
  factory $EventDtoCopyWith(EventDto value, $Res Function(EventDto) _then) = _$EventDtoCopyWithImpl;
@useResult
$Res call({
 String title, String description,@JsonKey(unknownEnumValue: EventCategory.other) EventCategory category,@TimestampConverter() DateTime startsAt, String location, int capacity, int availablePlaces, String organizerId, String organizerName, String? imageUrl,@NullableTimestampConverter() DateTime? createdAt,@NullableTimestampConverter() DateTime? updatedAt
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
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? description = null,Object? category = null,Object? startsAt = null,Object? location = null,Object? capacity = null,Object? availablePlaces = null,Object? organizerId = null,Object? organizerName = null,Object? imageUrl = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(EventDto(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
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
as DateTime?,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  String description, @JsonKey(unknownEnumValue: EventCategory.other)  EventCategory category, @TimestampConverter()  DateTime startsAt,  String location,  int capacity,  int availablePlaces,  String organizerId,  String organizerName,  String? imageUrl, @NullableTimestampConverter()  DateTime? createdAt, @NullableTimestampConverter()  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EventDto() when $default != null:
return $default(_that.title,_that.description,_that.category,_that.startsAt,_that.location,_that.capacity,_that.availablePlaces,_that.organizerId,_that.organizerName,_that.imageUrl,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  String description, @JsonKey(unknownEnumValue: EventCategory.other)  EventCategory category, @TimestampConverter()  DateTime startsAt,  String location,  int capacity,  int availablePlaces,  String organizerId,  String organizerName,  String? imageUrl, @NullableTimestampConverter()  DateTime? createdAt, @NullableTimestampConverter()  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _EventDto():
return $default(_that.title,_that.description,_that.category,_that.startsAt,_that.location,_that.capacity,_that.availablePlaces,_that.organizerId,_that.organizerName,_that.imageUrl,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  String description, @JsonKey(unknownEnumValue: EventCategory.other)  EventCategory category, @TimestampConverter()  DateTime startsAt,  String location,  int capacity,  int availablePlaces,  String organizerId,  String organizerName,  String? imageUrl, @NullableTimestampConverter()  DateTime? createdAt, @NullableTimestampConverter()  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _EventDto() when $default != null:
return $default(_that.title,_that.description,_that.category,_that.startsAt,_that.location,_that.capacity,_that.availablePlaces,_that.organizerId,_that.organizerName,_that.imageUrl,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EventDto extends EventDto {
  const _EventDto({required this.title, required this.description, @JsonKey(unknownEnumValue: EventCategory.other) required this.category, @TimestampConverter() required this.startsAt, required this.location, required this.capacity, required this.availablePlaces, required this.organizerId, required this.organizerName, this.imageUrl, @NullableTimestampConverter() this.createdAt, @NullableTimestampConverter() this.updatedAt}): super._();
  factory _EventDto.fromJson(Map<String, dynamic> json) => _$EventDtoFromJson(json);

@override final  String title;
@override final  String description;
@override@JsonKey(unknownEnumValue: EventCategory.other) final  EventCategory category;
@override@TimestampConverter() final  DateTime startsAt;
@override final  String location;
@override final  int capacity;
@override final  int availablePlaces;
@override final  String organizerId;
@override final  String organizerName;
@override final  String? imageUrl;
@override@NullableTimestampConverter() final  DateTime? createdAt;
@override@NullableTimestampConverter() final  DateTime? updatedAt;

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
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _EventDto&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.category, category) || other.category == category)&&(identical(other.startsAt, startsAt) || other.startsAt == startsAt)&&(identical(other.location, location) || other.location == location)&&(identical(other.capacity, capacity) || other.capacity == capacity)&&(identical(other.availablePlaces, availablePlaces) || other.availablePlaces == availablePlaces)&&(identical(other.organizerId, organizerId) || other.organizerId == organizerId)&&(identical(other.organizerName, organizerName) || other.organizerName == organizerName)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,title,description,category,startsAt,location,capacity,availablePlaces,organizerId,organizerName,imageUrl,createdAt,updatedAt);
}

@override
String toString() {
    return 'EventDto(title: $title, description: $description, category: $category, startsAt: $startsAt, location: $location, capacity: $capacity, availablePlaces: $availablePlaces, organizerId: $organizerId, organizerName: $organizerName, imageUrl: $imageUrl, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$EventDtoCopyWith<$Res> implements $EventDtoCopyWith<$Res> {
  factory _$EventDtoCopyWith(_EventDto value, $Res Function(_EventDto) _then) = __$EventDtoCopyWithImpl;
@override @useResult
$Res call({
 String title, String description,@JsonKey(unknownEnumValue: EventCategory.other) EventCategory category,@TimestampConverter() DateTime startsAt, String location, int capacity, int availablePlaces, String organizerId, String organizerName, String? imageUrl,@NullableTimestampConverter() DateTime? createdAt,@NullableTimestampConverter() DateTime? updatedAt
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
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? description = null,Object? category = null,Object? startsAt = null,Object? location = null,Object? capacity = null,Object? availablePlaces = null,Object? organizerId = null,Object? organizerName = null,Object? imageUrl = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_EventDto(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
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
as DateTime?,
  ));
}


}

// dart format on
