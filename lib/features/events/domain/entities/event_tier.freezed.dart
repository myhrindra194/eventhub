// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'event_tier.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$EventTier {

 String get id; String get name; int get capacity; int get available; String get description; int get price; int get order;
/// Create a copy of EventTier
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EventTierCopyWith<EventTier> get copyWith => _$EventTierCopyWithImpl<EventTier>(this as EventTier, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as EventTier;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EventTier&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.capacity, _this.capacity) || other.capacity == _this.capacity)&&(identical(other.available, _this.available) || other.available == _this.available)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.price, _this.price) || other.price == _this.price)&&(identical(other.order, _this.order) || other.order == _this.order));
}


@override
int get hashCode {
  final _this = this as EventTier;
  return Object.hash(runtimeType,_this.id,_this.name,_this.capacity,_this.available,_this.description,_this.price,_this.order);
}

@override
String toString() {
  final _this = this as EventTier;
  return 'EventTier(id: ${_this.id}, name: ${_this.name}, capacity: ${_this.capacity}, available: ${_this.available}, description: ${_this.description}, price: ${_this.price}, order: ${_this.order})';
}


}

/// @nodoc
abstract mixin class $EventTierCopyWith<$Res>  {
  factory $EventTierCopyWith(EventTier value, $Res Function(EventTier) _then) = _$EventTierCopyWithImpl;
@useResult
$Res call({
 String id, String name, int capacity, int available, String description, int price, int order
});




}
/// @nodoc
class _$EventTierCopyWithImpl<$Res>
    implements $EventTierCopyWith<$Res> {
  _$EventTierCopyWithImpl(this._self, this._then);

  final EventTier _self;
  final $Res Function(EventTier) _then;

/// Create a copy of EventTier
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? capacity = null,Object? available = null,Object? description = null,Object? price = null,Object? order = null,}) {
  return _then(EventTier(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,capacity: null == capacity ? _self.capacity : capacity // ignore: cast_nullable_to_non_nullable
as int,available: null == available ? _self.available : available // ignore: cast_nullable_to_non_nullable
as int,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as int,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [EventTier].
extension EventTierPatterns on EventTier {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EventTier value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EventTier() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EventTier value)  $default,){
final _that = this;
switch (_that) {
case _EventTier():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EventTier value)?  $default,){
final _that = this;
switch (_that) {
case _EventTier() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  int capacity,  int available,  String description,  int price,  int order)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EventTier() when $default != null:
return $default(_that.id,_that.name,_that.capacity,_that.available,_that.description,_that.price,_that.order);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  int capacity,  int available,  String description,  int price,  int order)  $default,) {final _that = this;
switch (_that) {
case _EventTier():
return $default(_that.id,_that.name,_that.capacity,_that.available,_that.description,_that.price,_that.order);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  int capacity,  int available,  String description,  int price,  int order)?  $default,) {final _that = this;
switch (_that) {
case _EventTier() when $default != null:
return $default(_that.id,_that.name,_that.capacity,_that.available,_that.description,_that.price,_that.order);case _:
  return null;

}
}

}

/// @nodoc


class _EventTier extends EventTier {
  const _EventTier({required this.id, required this.name, required this.capacity, required this.available, this.description = '', this.price = 0, this.order = 0}): super._();
  

@override final  String id;
@override final  String name;
@override final  int capacity;
@override final  int available;
@override@JsonKey() final  String description;
@override@JsonKey() final  int price;
@override@JsonKey() final  int order;

/// Create a copy of EventTier
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EventTierCopyWith<_EventTier> get copyWith => __$EventTierCopyWithImpl<_EventTier>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _EventTier&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.capacity, capacity) || other.capacity == capacity)&&(identical(other.available, available) || other.available == available)&&(identical(other.description, description) || other.description == description)&&(identical(other.price, price) || other.price == price)&&(identical(other.order, order) || other.order == order));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,name,capacity,available,description,price,order);
}

@override
String toString() {
    return 'EventTier(id: $id, name: $name, capacity: $capacity, available: $available, description: $description, price: $price, order: $order)';
}


}

/// @nodoc
abstract mixin class _$EventTierCopyWith<$Res> implements $EventTierCopyWith<$Res> {
  factory _$EventTierCopyWith(_EventTier value, $Res Function(_EventTier) _then) = __$EventTierCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, int capacity, int available, String description, int price, int order
});




}
/// @nodoc
class __$EventTierCopyWithImpl<$Res>
    implements _$EventTierCopyWith<$Res> {
  __$EventTierCopyWithImpl(this._self, this._then);

  final _EventTier _self;
  final $Res Function(_EventTier) _then;

/// Create a copy of EventTier
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? capacity = null,Object? available = null,Object? description = null,Object? price = null,Object? order = null,}) {
  return _then(_EventTier(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,capacity: null == capacity ? _self.capacity : capacity // ignore: cast_nullable_to_non_nullable
as int,available: null == available ? _self.available : available // ignore: cast_nullable_to_non_nullable
as int,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as int,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$EventTierDraft {

 String get name; int get capacity; String? get id; String get description; int get price;
/// Create a copy of EventTierDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EventTierDraftCopyWith<EventTierDraft> get copyWith => _$EventTierDraftCopyWithImpl<EventTierDraft>(this as EventTierDraft, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as EventTierDraft;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EventTierDraft&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.capacity, _this.capacity) || other.capacity == _this.capacity)&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.price, _this.price) || other.price == _this.price));
}


@override
int get hashCode {
  final _this = this as EventTierDraft;
  return Object.hash(runtimeType,_this.name,_this.capacity,_this.id,_this.description,_this.price);
}

@override
String toString() {
  final _this = this as EventTierDraft;
  return 'EventTierDraft(name: ${_this.name}, capacity: ${_this.capacity}, id: ${_this.id}, description: ${_this.description}, price: ${_this.price})';
}


}

/// @nodoc
abstract mixin class $EventTierDraftCopyWith<$Res>  {
  factory $EventTierDraftCopyWith(EventTierDraft value, $Res Function(EventTierDraft) _then) = _$EventTierDraftCopyWithImpl;
@useResult
$Res call({
 String name, int capacity, String? id, String description, int price
});




}
/// @nodoc
class _$EventTierDraftCopyWithImpl<$Res>
    implements $EventTierDraftCopyWith<$Res> {
  _$EventTierDraftCopyWithImpl(this._self, this._then);

  final EventTierDraft _self;
  final $Res Function(EventTierDraft) _then;

/// Create a copy of EventTierDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? capacity = null,Object? id = freezed,Object? description = null,Object? price = null,}) {
  return _then(EventTierDraft(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,capacity: null == capacity ? _self.capacity : capacity // ignore: cast_nullable_to_non_nullable
as int,id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [EventTierDraft].
extension EventTierDraftPatterns on EventTierDraft {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EventTierDraft value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EventTierDraft() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EventTierDraft value)  $default,){
final _that = this;
switch (_that) {
case _EventTierDraft():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EventTierDraft value)?  $default,){
final _that = this;
switch (_that) {
case _EventTierDraft() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  int capacity,  String? id,  String description,  int price)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EventTierDraft() when $default != null:
return $default(_that.name,_that.capacity,_that.id,_that.description,_that.price);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  int capacity,  String? id,  String description,  int price)  $default,) {final _that = this;
switch (_that) {
case _EventTierDraft():
return $default(_that.name,_that.capacity,_that.id,_that.description,_that.price);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  int capacity,  String? id,  String description,  int price)?  $default,) {final _that = this;
switch (_that) {
case _EventTierDraft() when $default != null:
return $default(_that.name,_that.capacity,_that.id,_that.description,_that.price);case _:
  return null;

}
}

}

/// @nodoc


class _EventTierDraft implements EventTierDraft {
  const _EventTierDraft({required this.name, required this.capacity, this.id, this.description = '', this.price = 0});
  

@override final  String name;
@override final  int capacity;
@override final  String? id;
@override@JsonKey() final  String description;
@override@JsonKey() final  int price;

/// Create a copy of EventTierDraft
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EventTierDraftCopyWith<_EventTierDraft> get copyWith => __$EventTierDraftCopyWithImpl<_EventTierDraft>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _EventTierDraft&&(identical(other.name, name) || other.name == name)&&(identical(other.capacity, capacity) || other.capacity == capacity)&&(identical(other.id, id) || other.id == id)&&(identical(other.description, description) || other.description == description)&&(identical(other.price, price) || other.price == price));
}


@override
int get hashCode {
    return Object.hash(runtimeType,name,capacity,id,description,price);
}

@override
String toString() {
    return 'EventTierDraft(name: $name, capacity: $capacity, id: $id, description: $description, price: $price)';
}


}

/// @nodoc
abstract mixin class _$EventTierDraftCopyWith<$Res> implements $EventTierDraftCopyWith<$Res> {
  factory _$EventTierDraftCopyWith(_EventTierDraft value, $Res Function(_EventTierDraft) _then) = __$EventTierDraftCopyWithImpl;
@override @useResult
$Res call({
 String name, int capacity, String? id, String description, int price
});




}
/// @nodoc
class __$EventTierDraftCopyWithImpl<$Res>
    implements _$EventTierDraftCopyWith<$Res> {
  __$EventTierDraftCopyWithImpl(this._self, this._then);

  final _EventTierDraft _self;
  final $Res Function(_EventTierDraft) _then;

/// Create a copy of EventTierDraft
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? capacity = null,Object? id = freezed,Object? description = null,Object? price = null,}) {
  return _then(_EventTierDraft(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,capacity: null == capacity ? _self.capacity : capacity // ignore: cast_nullable_to_non_nullable
as int,id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
