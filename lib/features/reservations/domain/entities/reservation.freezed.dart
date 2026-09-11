// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reservation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Reservation {

 String get id; String get eventId; String get userId; String get organizerId; String get userName; String get userEmail; String get eventTitle; DateTime get eventStartsAt; String get eventLocation; ReservationStatus get status; DateTime get reservedAt; DateTime? get cancelledAt;
/// Create a copy of Reservation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReservationCopyWith<Reservation> get copyWith => _$ReservationCopyWithImpl<Reservation>(this as Reservation, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Reservation;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Reservation&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.eventId, _this.eventId) || other.eventId == _this.eventId)&&(identical(other.userId, _this.userId) || other.userId == _this.userId)&&(identical(other.organizerId, _this.organizerId) || other.organizerId == _this.organizerId)&&(identical(other.userName, _this.userName) || other.userName == _this.userName)&&(identical(other.userEmail, _this.userEmail) || other.userEmail == _this.userEmail)&&(identical(other.eventTitle, _this.eventTitle) || other.eventTitle == _this.eventTitle)&&(identical(other.eventStartsAt, _this.eventStartsAt) || other.eventStartsAt == _this.eventStartsAt)&&(identical(other.eventLocation, _this.eventLocation) || other.eventLocation == _this.eventLocation)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.reservedAt, _this.reservedAt) || other.reservedAt == _this.reservedAt)&&(identical(other.cancelledAt, _this.cancelledAt) || other.cancelledAt == _this.cancelledAt));
}


@override
int get hashCode {
  final _this = this as Reservation;
  return Object.hash(runtimeType,_this.id,_this.eventId,_this.userId,_this.organizerId,_this.userName,_this.userEmail,_this.eventTitle,_this.eventStartsAt,_this.eventLocation,_this.status,_this.reservedAt,_this.cancelledAt);
}

@override
String toString() {
  final _this = this as Reservation;
  return 'Reservation(id: ${_this.id}, eventId: ${_this.eventId}, userId: ${_this.userId}, organizerId: ${_this.organizerId}, userName: ${_this.userName}, userEmail: ${_this.userEmail}, eventTitle: ${_this.eventTitle}, eventStartsAt: ${_this.eventStartsAt}, eventLocation: ${_this.eventLocation}, status: ${_this.status}, reservedAt: ${_this.reservedAt}, cancelledAt: ${_this.cancelledAt})';
}


}

/// @nodoc
abstract mixin class $ReservationCopyWith<$Res>  {
  factory $ReservationCopyWith(Reservation value, $Res Function(Reservation) _then) = _$ReservationCopyWithImpl;
@useResult
$Res call({
 String id, String eventId, String userId, String organizerId, String userName, String userEmail, String eventTitle, DateTime eventStartsAt, String eventLocation, ReservationStatus status, DateTime reservedAt, DateTime? cancelledAt
});




}
/// @nodoc
class _$ReservationCopyWithImpl<$Res>
    implements $ReservationCopyWith<$Res> {
  _$ReservationCopyWithImpl(this._self, this._then);

  final Reservation _self;
  final $Res Function(Reservation) _then;

/// Create a copy of Reservation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? eventId = null,Object? userId = null,Object? organizerId = null,Object? userName = null,Object? userEmail = null,Object? eventTitle = null,Object? eventStartsAt = null,Object? eventLocation = null,Object? status = null,Object? reservedAt = null,Object? cancelledAt = freezed,}) {
  return _then(Reservation(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
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


/// Adds pattern-matching-related methods to [Reservation].
extension ReservationPatterns on Reservation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Reservation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Reservation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Reservation value)  $default,){
final _that = this;
switch (_that) {
case _Reservation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Reservation value)?  $default,){
final _that = this;
switch (_that) {
case _Reservation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String eventId,  String userId,  String organizerId,  String userName,  String userEmail,  String eventTitle,  DateTime eventStartsAt,  String eventLocation,  ReservationStatus status,  DateTime reservedAt,  DateTime? cancelledAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Reservation() when $default != null:
return $default(_that.id,_that.eventId,_that.userId,_that.organizerId,_that.userName,_that.userEmail,_that.eventTitle,_that.eventStartsAt,_that.eventLocation,_that.status,_that.reservedAt,_that.cancelledAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String eventId,  String userId,  String organizerId,  String userName,  String userEmail,  String eventTitle,  DateTime eventStartsAt,  String eventLocation,  ReservationStatus status,  DateTime reservedAt,  DateTime? cancelledAt)  $default,) {final _that = this;
switch (_that) {
case _Reservation():
return $default(_that.id,_that.eventId,_that.userId,_that.organizerId,_that.userName,_that.userEmail,_that.eventTitle,_that.eventStartsAt,_that.eventLocation,_that.status,_that.reservedAt,_that.cancelledAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String eventId,  String userId,  String organizerId,  String userName,  String userEmail,  String eventTitle,  DateTime eventStartsAt,  String eventLocation,  ReservationStatus status,  DateTime reservedAt,  DateTime? cancelledAt)?  $default,) {final _that = this;
switch (_that) {
case _Reservation() when $default != null:
return $default(_that.id,_that.eventId,_that.userId,_that.organizerId,_that.userName,_that.userEmail,_that.eventTitle,_that.eventStartsAt,_that.eventLocation,_that.status,_that.reservedAt,_that.cancelledAt);case _:
  return null;

}
}

}

/// @nodoc


class _Reservation extends Reservation {
  const _Reservation({required this.id, required this.eventId, required this.userId, required this.organizerId, required this.userName, required this.userEmail, required this.eventTitle, required this.eventStartsAt, required this.eventLocation, required this.status, required this.reservedAt, this.cancelledAt}): super._();
  

@override final  String id;
@override final  String eventId;
@override final  String userId;
@override final  String organizerId;
@override final  String userName;
@override final  String userEmail;
@override final  String eventTitle;
@override final  DateTime eventStartsAt;
@override final  String eventLocation;
@override final  ReservationStatus status;
@override final  DateTime reservedAt;
@override final  DateTime? cancelledAt;

/// Create a copy of Reservation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReservationCopyWith<_Reservation> get copyWith => __$ReservationCopyWithImpl<_Reservation>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Reservation&&(identical(other.id, id) || other.id == id)&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.organizerId, organizerId) || other.organizerId == organizerId)&&(identical(other.userName, userName) || other.userName == userName)&&(identical(other.userEmail, userEmail) || other.userEmail == userEmail)&&(identical(other.eventTitle, eventTitle) || other.eventTitle == eventTitle)&&(identical(other.eventStartsAt, eventStartsAt) || other.eventStartsAt == eventStartsAt)&&(identical(other.eventLocation, eventLocation) || other.eventLocation == eventLocation)&&(identical(other.status, status) || other.status == status)&&(identical(other.reservedAt, reservedAt) || other.reservedAt == reservedAt)&&(identical(other.cancelledAt, cancelledAt) || other.cancelledAt == cancelledAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,eventId,userId,organizerId,userName,userEmail,eventTitle,eventStartsAt,eventLocation,status,reservedAt,cancelledAt);
}

@override
String toString() {
    return 'Reservation(id: $id, eventId: $eventId, userId: $userId, organizerId: $organizerId, userName: $userName, userEmail: $userEmail, eventTitle: $eventTitle, eventStartsAt: $eventStartsAt, eventLocation: $eventLocation, status: $status, reservedAt: $reservedAt, cancelledAt: $cancelledAt)';
}


}

/// @nodoc
abstract mixin class _$ReservationCopyWith<$Res> implements $ReservationCopyWith<$Res> {
  factory _$ReservationCopyWith(_Reservation value, $Res Function(_Reservation) _then) = __$ReservationCopyWithImpl;
@override @useResult
$Res call({
 String id, String eventId, String userId, String organizerId, String userName, String userEmail, String eventTitle, DateTime eventStartsAt, String eventLocation, ReservationStatus status, DateTime reservedAt, DateTime? cancelledAt
});




}
/// @nodoc
class __$ReservationCopyWithImpl<$Res>
    implements _$ReservationCopyWith<$Res> {
  __$ReservationCopyWithImpl(this._self, this._then);

  final _Reservation _self;
  final $Res Function(_Reservation) _then;

/// Create a copy of Reservation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? eventId = null,Object? userId = null,Object? organizerId = null,Object? userName = null,Object? userEmail = null,Object? eventTitle = null,Object? eventStartsAt = null,Object? eventLocation = null,Object? status = null,Object? reservedAt = null,Object? cancelledAt = freezed,}) {
  return _then(_Reservation(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
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
