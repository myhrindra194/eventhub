// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'event_draft.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$EventDraft {

 String get title; String get description; EventCategory get category; DateTime get startsAt; String get location; int get capacity; String? get imageUrl;
/// Create a copy of EventDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EventDraftCopyWith<EventDraft> get copyWith => _$EventDraftCopyWithImpl<EventDraft>(this as EventDraft, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as EventDraft;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EventDraft&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.category, _this.category) || other.category == _this.category)&&(identical(other.startsAt, _this.startsAt) || other.startsAt == _this.startsAt)&&(identical(other.location, _this.location) || other.location == _this.location)&&(identical(other.capacity, _this.capacity) || other.capacity == _this.capacity)&&(identical(other.imageUrl, _this.imageUrl) || other.imageUrl == _this.imageUrl));
}


@override
int get hashCode {
  final _this = this as EventDraft;
  return Object.hash(runtimeType,_this.title,_this.description,_this.category,_this.startsAt,_this.location,_this.capacity,_this.imageUrl);
}

@override
String toString() {
  final _this = this as EventDraft;
  return 'EventDraft(title: ${_this.title}, description: ${_this.description}, category: ${_this.category}, startsAt: ${_this.startsAt}, location: ${_this.location}, capacity: ${_this.capacity}, imageUrl: ${_this.imageUrl})';
}


}

/// @nodoc
abstract mixin class $EventDraftCopyWith<$Res>  {
  factory $EventDraftCopyWith(EventDraft value, $Res Function(EventDraft) _then) = _$EventDraftCopyWithImpl;
@useResult
$Res call({
 String title, String description, EventCategory category, DateTime startsAt, String location, int capacity, String? imageUrl
});




}
/// @nodoc
class _$EventDraftCopyWithImpl<$Res>
    implements $EventDraftCopyWith<$Res> {
  _$EventDraftCopyWithImpl(this._self, this._then);

  final EventDraft _self;
  final $Res Function(EventDraft) _then;

/// Create a copy of EventDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? description = null,Object? category = null,Object? startsAt = null,Object? location = null,Object? capacity = null,Object? imageUrl = freezed,}) {
  return _then(EventDraft(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as EventCategory,startsAt: null == startsAt ? _self.startsAt : startsAt // ignore: cast_nullable_to_non_nullable
as DateTime,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String,capacity: null == capacity ? _self.capacity : capacity // ignore: cast_nullable_to_non_nullable
as int,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [EventDraft].
extension EventDraftPatterns on EventDraft {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EventDraft value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EventDraft() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EventDraft value)  $default,){
final _that = this;
switch (_that) {
case _EventDraft():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EventDraft value)?  $default,){
final _that = this;
switch (_that) {
case _EventDraft() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  String description,  EventCategory category,  DateTime startsAt,  String location,  int capacity,  String? imageUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EventDraft() when $default != null:
return $default(_that.title,_that.description,_that.category,_that.startsAt,_that.location,_that.capacity,_that.imageUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  String description,  EventCategory category,  DateTime startsAt,  String location,  int capacity,  String? imageUrl)  $default,) {final _that = this;
switch (_that) {
case _EventDraft():
return $default(_that.title,_that.description,_that.category,_that.startsAt,_that.location,_that.capacity,_that.imageUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  String description,  EventCategory category,  DateTime startsAt,  String location,  int capacity,  String? imageUrl)?  $default,) {final _that = this;
switch (_that) {
case _EventDraft() when $default != null:
return $default(_that.title,_that.description,_that.category,_that.startsAt,_that.location,_that.capacity,_that.imageUrl);case _:
  return null;

}
}

}

/// @nodoc


class _EventDraft extends EventDraft {
  const _EventDraft({required this.title, required this.description, required this.category, required this.startsAt, required this.location, required this.capacity, this.imageUrl}): super._();
  

@override final  String title;
@override final  String description;
@override final  EventCategory category;
@override final  DateTime startsAt;
@override final  String location;
@override final  int capacity;
@override final  String? imageUrl;

/// Create a copy of EventDraft
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EventDraftCopyWith<_EventDraft> get copyWith => __$EventDraftCopyWithImpl<_EventDraft>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _EventDraft&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.category, category) || other.category == category)&&(identical(other.startsAt, startsAt) || other.startsAt == startsAt)&&(identical(other.location, location) || other.location == location)&&(identical(other.capacity, capacity) || other.capacity == capacity)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl));
}


@override
int get hashCode {
    return Object.hash(runtimeType,title,description,category,startsAt,location,capacity,imageUrl);
}

@override
String toString() {
    return 'EventDraft(title: $title, description: $description, category: $category, startsAt: $startsAt, location: $location, capacity: $capacity, imageUrl: $imageUrl)';
}


}

/// @nodoc
abstract mixin class _$EventDraftCopyWith<$Res> implements $EventDraftCopyWith<$Res> {
  factory _$EventDraftCopyWith(_EventDraft value, $Res Function(_EventDraft) _then) = __$EventDraftCopyWithImpl;
@override @useResult
$Res call({
 String title, String description, EventCategory category, DateTime startsAt, String location, int capacity, String? imageUrl
});




}
/// @nodoc
class __$EventDraftCopyWithImpl<$Res>
    implements _$EventDraftCopyWith<$Res> {
  __$EventDraftCopyWithImpl(this._self, this._then);

  final _EventDraft _self;
  final $Res Function(_EventDraft) _then;

/// Create a copy of EventDraft
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? description = null,Object? category = null,Object? startsAt = null,Object? location = null,Object? capacity = null,Object? imageUrl = freezed,}) {
  return _then(_EventDraft(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as EventCategory,startsAt: null == startsAt ? _self.startsAt : startsAt // ignore: cast_nullable_to_non_nullable
as DateTime,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String,capacity: null == capacity ? _self.capacity : capacity // ignore: cast_nullable_to_non_nullable
as int,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
