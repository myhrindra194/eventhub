// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reservation_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ReservationDto {

 String get eventId; String get userId; String get organizerId; String get userName; String get userEmail; String get eventTitle;@TimestampConverter() DateTime get eventStartsAt; String get eventLocation;@JsonKey(unknownEnumValue: ReservationStatus.cancelled) ReservationStatus get status;@TimestampConverter() DateTime get reservedAt;@NullableTimestampConverter() DateTime? get cancelledAt;
/// Create a copy of ReservationDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReservationDtoCopyWith<ReservationDto> get copyWith => _$ReservationDtoCopyWithImpl<ReservationDto>(this as ReservationDto, _$identity);

  /// Serializes this ReservationDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ReservationDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReservationDto&&(identical(other.eventId, _this.eventId) || other.eventId == _this.eventId)&&(identical(other.userId, _this.userId) || other.userId == _this.userId)&&(identical(other.organizerId, _this.organizerId) || other.organizerId == _this.organizerId)&&(identical(other.userName, _this.userName) || other.userName == _this.userName)&&(identical(other.userEmail, _this.userEmail) || other.userEmail == _this.userEmail)&&(identical(other.eventTitle, _this.eventTitle) || other.eventTitle == _this.eventTitle)&&(identical(other.eventStartsAt, _this.eventStartsAt) || other.eventStartsAt == _this.eventStartsAt)&&(identical(other.eventLocation, _this.eventLocation) || other.eventLocation == _this.eventLocation)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.reservedAt, _this.reservedAt) || other.reservedAt == _this.reservedAt)&&(identical(other.cancelledAt, _this.cancelledAt) || other.cancelledAt == _this.cancelledAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ReservationDto;
  return Object.hash(runtimeType,_this.eventId,_this.userId,_this.organizerId,_this.userName,_this.userEmail,_this.eventTitle,_this.eventStartsAt,_this.eventLocation,_this.status,_this.reservedAt,_this.cancelledAt);
}

@override
String toString() {
  final _this = this as ReservationDto;
  return 'ReservationDto(eventId: ${_this.eventId}, userId: ${_this.userId}, organizerId: ${_this.organizerId}, userName: ${_this.userName}, userEmail: ${_this.userEmail}, eventTitle: ${_this.eventTitle}, eventStartsAt: ${_this.eventStartsAt}, eventLocation: ${_this.eventLocation}, status: ${_this.status}, reservedAt: ${_this.reservedAt}, cancelledAt: ${_this.cancelledAt})';
}


}

/// @nodoc
abstract mixin class $ReservationDtoCopyWith<$Res>  {
  factory $ReservationDtoCopyWith(ReservationDto value, $Res Function(ReservationDto) _then) = _$ReservationDtoCopyWithImpl;
@useResult
$Res call({
 String eventId, String userId, String organizerId, String userName, String userEmail, String eventTitle,@TimestampConverter() DateTime eventStartsAt, String eventLocation,@JsonKey(unknownEnumValue: ReservationStatus.cancelled) ReservationStatus status,@TimestampConverter() DateTime reservedAt,@NullableTimestampConverter() DateTime? cancelledAt
});




}
/// @nodoc
class _$ReservationDtoCopyWithImpl<$Res>
    implements $ReservationDtoCopyWith<$Res> {
  _$ReservationDtoCopyWithImpl(this._self, this._then);

  final ReservationDto _self;
  final $Res Function(ReservationDto) _then;

/// Create a copy of ReservationDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? eventId = null,Object? userId = null,Object? organizerId = null,Object? userName = null,Object? userEmail = null,Object? eventTitle = null,Object? eventStartsAt = null,Object? eventLocation = null,Object? status = null,Object? reservedAt = null,Object? cancelledAt = freezed,}) {
  return _then(ReservationDto(
eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,organizerId: null == organizerId ? _self.organizerId : organizerId // ignore: cast_nullable_to_non_nullable
as String,userName: null == userName ? _self.userName : userName // ignore: cast_nullable_to_non_nullable
as String,userEmail: null == userEmail ? _self.userEmail : userEmail // ignore: cast_nullable_to_non_nullable
as String,eventTitle: null == eventTitle ? _self.eventTitle : eventTitle // ignore: cast_nullable_to_non_nullable
as String,eventStartsAt: null == eventStartsAt ? _self.eventStartsAt : eventStartsAt // ignore: cast_nullable_to_non_nullable
as DateTime,eventLocation: null == eventLocation ? _self.eventLocation : eventLocation // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ReservationStatus,reservedAt: null == reservedAt ? _self.reservedAt : reservedAt // ignore: cast_nullable_to_non_nullable
as DateTime,cancelledAt: freezed == cancelledAt ? _self.cancelledAt : cancelledAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [ReservationDto].
extension ReservationDtoPatterns on ReservationDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReservationDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReservationDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReservationDto value)  $default,){
final _that = this;
switch (_that) {
case _ReservationDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReservationDto value)?  $default,){
final _that = this;
switch (_that) {
case _ReservationDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String eventId,  String userId,  String organizerId,  String userName,  String userEmail,  String eventTitle, @TimestampConverter()  DateTime eventStartsAt,  String eventLocation, @JsonKey(unknownEnumValue: ReservationStatus.cancelled)  ReservationStatus status, @TimestampConverter()  DateTime reservedAt, @NullableTimestampConverter()  DateTime? cancelledAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReservationDto() when $default != null:
return $default(_that.eventId,_that.userId,_that.organizerId,_that.userName,_that.userEmail,_that.eventTitle,_that.eventStartsAt,_that.eventLocation,_that.status,_that.reservedAt,_that.cancelledAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String eventId,  String userId,  String organizerId,  String userName,  String userEmail,  String eventTitle, @TimestampConverter()  DateTime eventStartsAt,  String eventLocation, @JsonKey(unknownEnumValue: ReservationStatus.cancelled)  ReservationStatus status, @TimestampConverter()  DateTime reservedAt, @NullableTimestampConverter()  DateTime? cancelledAt)  $default,) {final _that = this;
switch (_that) {
case _ReservationDto():
return $default(_that.eventId,_that.userId,_that.organizerId,_that.userName,_that.userEmail,_that.eventTitle,_that.eventStartsAt,_that.eventLocation,_that.status,_that.reservedAt,_that.cancelledAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String eventId,  String userId,  String organizerId,  String userName,  String userEmail,  String eventTitle, @TimestampConverter()  DateTime eventStartsAt,  String eventLocation, @JsonKey(unknownEnumValue: ReservationStatus.cancelled)  ReservationStatus status, @TimestampConverter()  DateTime reservedAt, @NullableTimestampConverter()  DateTime? cancelledAt)?  $default,) {final _that = this;
switch (_that) {
case _ReservationDto() when $default != null:
return $default(_that.eventId,_that.userId,_that.organizerId,_that.userName,_that.userEmail,_that.eventTitle,_that.eventStartsAt,_that.eventLocation,_that.status,_that.reservedAt,_that.cancelledAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReservationDto extends ReservationDto {
  const _ReservationDto({required this.eventId, required this.userId, required this.organizerId, required this.userName, required this.userEmail, required this.eventTitle, @TimestampConverter() required this.eventStartsAt, required this.eventLocation, @JsonKey(unknownEnumValue: ReservationStatus.cancelled) required this.status, @TimestampConverter() required this.reservedAt, @NullableTimestampConverter() this.cancelledAt}): super._();
  factory _ReservationDto.fromJson(Map<String, dynamic> json) => _$ReservationDtoFromJson(json);

@override final  String eventId;
@override final  String userId;
@override final  String organizerId;
@override final  String userName;
@override final  String userEmail;
@override final  String eventTitle;
@override@TimestampConverter() final  DateTime eventStartsAt;
@override final  String eventLocation;
@override@JsonKey(unknownEnumValue: ReservationStatus.cancelled) final  ReservationStatus status;
@override@TimestampConverter() final  DateTime reservedAt;
@override@NullableTimestampConverter() final  DateTime? cancelledAt;

/// Create a copy of ReservationDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReservationDtoCopyWith<_ReservationDto> get copyWith => __$ReservationDtoCopyWithImpl<_ReservationDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReservationDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReservationDto&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.organizerId, organizerId) || other.organizerId == organizerId)&&(identical(other.userName, userName) || other.userName == userName)&&(identical(other.userEmail, userEmail) || other.userEmail == userEmail)&&(identical(other.eventTitle, eventTitle) || other.eventTitle == eventTitle)&&(identical(other.eventStartsAt, eventStartsAt) || other.eventStartsAt == eventStartsAt)&&(identical(other.eventLocation, eventLocation) || other.eventLocation == eventLocation)&&(identical(other.status, status) || other.status == status)&&(identical(other.reservedAt, reservedAt) || other.reservedAt == reservedAt)&&(identical(other.cancelledAt, cancelledAt) || other.cancelledAt == cancelledAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,eventId,userId,organizerId,userName,userEmail,eventTitle,eventStartsAt,eventLocation,status,reservedAt,cancelledAt);
}

@override
String toString() {
    return 'ReservationDto(eventId: $eventId, userId: $userId, organizerId: $organizerId, userName: $userName, userEmail: $userEmail, eventTitle: $eventTitle, eventStartsAt: $eventStartsAt, eventLocation: $eventLocation, status: $status, reservedAt: $reservedAt, cancelledAt: $cancelledAt)';
}


}

/// @nodoc
abstract mixin class _$ReservationDtoCopyWith<$Res> implements $ReservationDtoCopyWith<$Res> {
  factory _$ReservationDtoCopyWith(_ReservationDto value, $Res Function(_ReservationDto) _then) = __$ReservationDtoCopyWithImpl;
@override @useResult
$Res call({
 String eventId, String userId, String organizerId, String userName, String userEmail, String eventTitle,@TimestampConverter() DateTime eventStartsAt, String eventLocation,@JsonKey(unknownEnumValue: ReservationStatus.cancelled) ReservationStatus status,@TimestampConverter() DateTime reservedAt,@NullableTimestampConverter() DateTime? cancelledAt
});




}
/// @nodoc
class __$ReservationDtoCopyWithImpl<$Res>
    implements _$ReservationDtoCopyWith<$Res> {
  __$ReservationDtoCopyWithImpl(this._self, this._then);

  final _ReservationDto _self;
  final $Res Function(_ReservationDto) _then;

/// Create a copy of ReservationDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? eventId = null,Object? userId = null,Object? organizerId = null,Object? userName = null,Object? userEmail = null,Object? eventTitle = null,Object? eventStartsAt = null,Object? eventLocation = null,Object? status = null,Object? reservedAt = null,Object? cancelledAt = freezed,}) {
  return _then(_ReservationDto(
eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,organizerId: null == organizerId ? _self.organizerId : organizerId // ignore: cast_nullable_to_non_nullable
as String,userName: null == userName ? _self.userName : userName // ignore: cast_nullable_to_non_nullable
as String,userEmail: null == userEmail ? _self.userEmail : userEmail // ignore: cast_nullable_to_non_nullable
as String,eventTitle: null == eventTitle ? _self.eventTitle : eventTitle // ignore: cast_nullable_to_non_nullable
as String,eventStartsAt: null == eventStartsAt ? _self.eventStartsAt : eventStartsAt // ignore: cast_nullable_to_non_nullable
as DateTime,eventLocation: null == eventLocation ? _self.eventLocation : eventLocation // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ReservationStatus,reservedAt: null == reservedAt ? _self.reservedAt : reservedAt // ignore: cast_nullable_to_non_nullable
as DateTime,cancelledAt: freezed == cancelledAt ? _self.cancelledAt : cancelledAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
