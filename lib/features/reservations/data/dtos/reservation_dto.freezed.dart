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

 String get id;/// The three references become null when the event or an account is
/// deleted; the snapshot columns stay.
 String? get eventId; String? get userId; String? get organizerId; String get userName; String get userEmail; String get eventTitle;@TimestampConverter() DateTime get eventStartsAt; String get eventLocation;@JsonKey(unknownEnumValue: ReservationStatus.cancelled) ReservationStatus get status;@TimestampConverter() DateTime get reservedAt;@NullableTimestampConverter() DateTime? get cancelledAt; String? get tierId; String? get tierName; int get pricePaid; int? get amountDue; String? get currency; String? get paymentStatus; String? get checkoutUrl;@NullableTimestampConverter() DateTime? get holdExpiresAt;
/// Create a copy of ReservationDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReservationDtoCopyWith<ReservationDto> get copyWith => _$ReservationDtoCopyWithImpl<ReservationDto>(this as ReservationDto, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ReservationDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReservationDto&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.eventId, _this.eventId) || other.eventId == _this.eventId)&&(identical(other.userId, _this.userId) || other.userId == _this.userId)&&(identical(other.organizerId, _this.organizerId) || other.organizerId == _this.organizerId)&&(identical(other.userName, _this.userName) || other.userName == _this.userName)&&(identical(other.userEmail, _this.userEmail) || other.userEmail == _this.userEmail)&&(identical(other.eventTitle, _this.eventTitle) || other.eventTitle == _this.eventTitle)&&(identical(other.eventStartsAt, _this.eventStartsAt) || other.eventStartsAt == _this.eventStartsAt)&&(identical(other.eventLocation, _this.eventLocation) || other.eventLocation == _this.eventLocation)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.reservedAt, _this.reservedAt) || other.reservedAt == _this.reservedAt)&&(identical(other.cancelledAt, _this.cancelledAt) || other.cancelledAt == _this.cancelledAt)&&(identical(other.tierId, _this.tierId) || other.tierId == _this.tierId)&&(identical(other.tierName, _this.tierName) || other.tierName == _this.tierName)&&(identical(other.pricePaid, _this.pricePaid) || other.pricePaid == _this.pricePaid)&&(identical(other.amountDue, _this.amountDue) || other.amountDue == _this.amountDue)&&(identical(other.currency, _this.currency) || other.currency == _this.currency)&&(identical(other.paymentStatus, _this.paymentStatus) || other.paymentStatus == _this.paymentStatus)&&(identical(other.checkoutUrl, _this.checkoutUrl) || other.checkoutUrl == _this.checkoutUrl)&&(identical(other.holdExpiresAt, _this.holdExpiresAt) || other.holdExpiresAt == _this.holdExpiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ReservationDto;
  return Object.hashAll([runtimeType,_this.id,_this.eventId,_this.userId,_this.organizerId,_this.userName,_this.userEmail,_this.eventTitle,_this.eventStartsAt,_this.eventLocation,_this.status,_this.reservedAt,_this.cancelledAt,_this.tierId,_this.tierName,_this.pricePaid,_this.amountDue,_this.currency,_this.paymentStatus,_this.checkoutUrl,_this.holdExpiresAt]);
}

@override
String toString() {
  final _this = this as ReservationDto;
  return 'ReservationDto(id: ${_this.id}, eventId: ${_this.eventId}, userId: ${_this.userId}, organizerId: ${_this.organizerId}, userName: ${_this.userName}, userEmail: ${_this.userEmail}, eventTitle: ${_this.eventTitle}, eventStartsAt: ${_this.eventStartsAt}, eventLocation: ${_this.eventLocation}, status: ${_this.status}, reservedAt: ${_this.reservedAt}, cancelledAt: ${_this.cancelledAt}, tierId: ${_this.tierId}, tierName: ${_this.tierName}, pricePaid: ${_this.pricePaid}, amountDue: ${_this.amountDue}, currency: ${_this.currency}, paymentStatus: ${_this.paymentStatus}, checkoutUrl: ${_this.checkoutUrl}, holdExpiresAt: ${_this.holdExpiresAt})';
}


}

/// @nodoc
abstract mixin class $ReservationDtoCopyWith<$Res>  {
  factory $ReservationDtoCopyWith(ReservationDto value, $Res Function(ReservationDto) _then) = _$ReservationDtoCopyWithImpl;
@useResult
$Res call({
 String id, String? eventId, String? userId, String? organizerId, String userName, String userEmail, String eventTitle,@TimestampConverter() DateTime eventStartsAt, String eventLocation,@JsonKey(unknownEnumValue: ReservationStatus.cancelled) ReservationStatus status,@TimestampConverter() DateTime reservedAt,@NullableTimestampConverter() DateTime? cancelledAt, String? tierId, String? tierName, int pricePaid, int? amountDue, String? currency, String? paymentStatus, String? checkoutUrl,@NullableTimestampConverter() DateTime? holdExpiresAt
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? eventId = freezed,Object? userId = freezed,Object? organizerId = freezed,Object? userName = null,Object? userEmail = null,Object? eventTitle = null,Object? eventStartsAt = null,Object? eventLocation = null,Object? status = null,Object? reservedAt = null,Object? cancelledAt = freezed,Object? tierId = freezed,Object? tierName = freezed,Object? pricePaid = null,Object? amountDue = freezed,Object? currency = freezed,Object? paymentStatus = freezed,Object? checkoutUrl = freezed,Object? holdExpiresAt = freezed,}) {
  return _then(ReservationDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,eventId: freezed == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String?,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,organizerId: freezed == organizerId ? _self.organizerId : organizerId // ignore: cast_nullable_to_non_nullable
as String?,userName: null == userName ? _self.userName : userName // ignore: cast_nullable_to_non_nullable
as String,userEmail: null == userEmail ? _self.userEmail : userEmail // ignore: cast_nullable_to_non_nullable
as String,eventTitle: null == eventTitle ? _self.eventTitle : eventTitle // ignore: cast_nullable_to_non_nullable
as String,eventStartsAt: null == eventStartsAt ? _self.eventStartsAt : eventStartsAt // ignore: cast_nullable_to_non_nullable
as DateTime,eventLocation: null == eventLocation ? _self.eventLocation : eventLocation // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ReservationStatus,reservedAt: null == reservedAt ? _self.reservedAt : reservedAt // ignore: cast_nullable_to_non_nullable
as DateTime,cancelledAt: freezed == cancelledAt ? _self.cancelledAt : cancelledAt // ignore: cast_nullable_to_non_nullable
as DateTime?,tierId: freezed == tierId ? _self.tierId : tierId // ignore: cast_nullable_to_non_nullable
as String?,tierName: freezed == tierName ? _self.tierName : tierName // ignore: cast_nullable_to_non_nullable
as String?,pricePaid: null == pricePaid ? _self.pricePaid : pricePaid // ignore: cast_nullable_to_non_nullable
as int,amountDue: freezed == amountDue ? _self.amountDue : amountDue // ignore: cast_nullable_to_non_nullable
as int?,currency: freezed == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String?,paymentStatus: freezed == paymentStatus ? _self.paymentStatus : paymentStatus // ignore: cast_nullable_to_non_nullable
as String?,checkoutUrl: freezed == checkoutUrl ? _self.checkoutUrl : checkoutUrl // ignore: cast_nullable_to_non_nullable
as String?,holdExpiresAt: freezed == holdExpiresAt ? _self.holdExpiresAt : holdExpiresAt // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? eventId,  String? userId,  String? organizerId,  String userName,  String userEmail,  String eventTitle, @TimestampConverter()  DateTime eventStartsAt,  String eventLocation, @JsonKey(unknownEnumValue: ReservationStatus.cancelled)  ReservationStatus status, @TimestampConverter()  DateTime reservedAt, @NullableTimestampConverter()  DateTime? cancelledAt,  String? tierId,  String? tierName,  int pricePaid,  int? amountDue,  String? currency,  String? paymentStatus,  String? checkoutUrl, @NullableTimestampConverter()  DateTime? holdExpiresAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReservationDto() when $default != null:
return $default(_that.id,_that.eventId,_that.userId,_that.organizerId,_that.userName,_that.userEmail,_that.eventTitle,_that.eventStartsAt,_that.eventLocation,_that.status,_that.reservedAt,_that.cancelledAt,_that.tierId,_that.tierName,_that.pricePaid,_that.amountDue,_that.currency,_that.paymentStatus,_that.checkoutUrl,_that.holdExpiresAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? eventId,  String? userId,  String? organizerId,  String userName,  String userEmail,  String eventTitle, @TimestampConverter()  DateTime eventStartsAt,  String eventLocation, @JsonKey(unknownEnumValue: ReservationStatus.cancelled)  ReservationStatus status, @TimestampConverter()  DateTime reservedAt, @NullableTimestampConverter()  DateTime? cancelledAt,  String? tierId,  String? tierName,  int pricePaid,  int? amountDue,  String? currency,  String? paymentStatus,  String? checkoutUrl, @NullableTimestampConverter()  DateTime? holdExpiresAt)  $default,) {final _that = this;
switch (_that) {
case _ReservationDto():
return $default(_that.id,_that.eventId,_that.userId,_that.organizerId,_that.userName,_that.userEmail,_that.eventTitle,_that.eventStartsAt,_that.eventLocation,_that.status,_that.reservedAt,_that.cancelledAt,_that.tierId,_that.tierName,_that.pricePaid,_that.amountDue,_that.currency,_that.paymentStatus,_that.checkoutUrl,_that.holdExpiresAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? eventId,  String? userId,  String? organizerId,  String userName,  String userEmail,  String eventTitle, @TimestampConverter()  DateTime eventStartsAt,  String eventLocation, @JsonKey(unknownEnumValue: ReservationStatus.cancelled)  ReservationStatus status, @TimestampConverter()  DateTime reservedAt, @NullableTimestampConverter()  DateTime? cancelledAt,  String? tierId,  String? tierName,  int pricePaid,  int? amountDue,  String? currency,  String? paymentStatus,  String? checkoutUrl, @NullableTimestampConverter()  DateTime? holdExpiresAt)?  $default,) {final _that = this;
switch (_that) {
case _ReservationDto() when $default != null:
return $default(_that.id,_that.eventId,_that.userId,_that.organizerId,_that.userName,_that.userEmail,_that.eventTitle,_that.eventStartsAt,_that.eventLocation,_that.status,_that.reservedAt,_that.cancelledAt,_that.tierId,_that.tierName,_that.pricePaid,_that.amountDue,_that.currency,_that.paymentStatus,_that.checkoutUrl,_that.holdExpiresAt);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class _ReservationDto extends ReservationDto {
  const _ReservationDto({required this.id, this.eventId, this.userId, this.organizerId, required this.userName, required this.userEmail, required this.eventTitle, @TimestampConverter() required this.eventStartsAt, required this.eventLocation, @JsonKey(unknownEnumValue: ReservationStatus.cancelled) required this.status, @TimestampConverter() required this.reservedAt, @NullableTimestampConverter() this.cancelledAt, this.tierId, this.tierName, this.pricePaid = 0, this.amountDue, this.currency, this.paymentStatus, this.checkoutUrl, @NullableTimestampConverter() this.holdExpiresAt}): super._();
  factory _ReservationDto.fromJson(Map<String, dynamic> json) => _$ReservationDtoFromJson(json);

@override final  String id;
/// The three references become null when the event or an account is
/// deleted; the snapshot columns stay.
@override final  String? eventId;
@override final  String? userId;
@override final  String? organizerId;
@override final  String userName;
@override final  String userEmail;
@override final  String eventTitle;
@override@TimestampConverter() final  DateTime eventStartsAt;
@override final  String eventLocation;
@override@JsonKey(unknownEnumValue: ReservationStatus.cancelled) final  ReservationStatus status;
@override@TimestampConverter() final  DateTime reservedAt;
@override@NullableTimestampConverter() final  DateTime? cancelledAt;
@override final  String? tierId;
@override final  String? tierName;
@override@JsonKey() final  int pricePaid;
@override final  int? amountDue;
@override final  String? currency;
@override final  String? paymentStatus;
@override final  String? checkoutUrl;
@override@NullableTimestampConverter() final  DateTime? holdExpiresAt;

/// Create a copy of ReservationDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReservationDtoCopyWith<_ReservationDto> get copyWith => __$ReservationDtoCopyWithImpl<_ReservationDto>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReservationDto&&(identical(other.id, id) || other.id == id)&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.organizerId, organizerId) || other.organizerId == organizerId)&&(identical(other.userName, userName) || other.userName == userName)&&(identical(other.userEmail, userEmail) || other.userEmail == userEmail)&&(identical(other.eventTitle, eventTitle) || other.eventTitle == eventTitle)&&(identical(other.eventStartsAt, eventStartsAt) || other.eventStartsAt == eventStartsAt)&&(identical(other.eventLocation, eventLocation) || other.eventLocation == eventLocation)&&(identical(other.status, status) || other.status == status)&&(identical(other.reservedAt, reservedAt) || other.reservedAt == reservedAt)&&(identical(other.cancelledAt, cancelledAt) || other.cancelledAt == cancelledAt)&&(identical(other.tierId, tierId) || other.tierId == tierId)&&(identical(other.tierName, tierName) || other.tierName == tierName)&&(identical(other.pricePaid, pricePaid) || other.pricePaid == pricePaid)&&(identical(other.amountDue, amountDue) || other.amountDue == amountDue)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.paymentStatus, paymentStatus) || other.paymentStatus == paymentStatus)&&(identical(other.checkoutUrl, checkoutUrl) || other.checkoutUrl == checkoutUrl)&&(identical(other.holdExpiresAt, holdExpiresAt) || other.holdExpiresAt == holdExpiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hashAll([runtimeType,id,eventId,userId,organizerId,userName,userEmail,eventTitle,eventStartsAt,eventLocation,status,reservedAt,cancelledAt,tierId,tierName,pricePaid,amountDue,currency,paymentStatus,checkoutUrl,holdExpiresAt]);
}

@override
String toString() {
    return 'ReservationDto(id: $id, eventId: $eventId, userId: $userId, organizerId: $organizerId, userName: $userName, userEmail: $userEmail, eventTitle: $eventTitle, eventStartsAt: $eventStartsAt, eventLocation: $eventLocation, status: $status, reservedAt: $reservedAt, cancelledAt: $cancelledAt, tierId: $tierId, tierName: $tierName, pricePaid: $pricePaid, amountDue: $amountDue, currency: $currency, paymentStatus: $paymentStatus, checkoutUrl: $checkoutUrl, holdExpiresAt: $holdExpiresAt)';
}


}

/// @nodoc
abstract mixin class _$ReservationDtoCopyWith<$Res> implements $ReservationDtoCopyWith<$Res> {
  factory _$ReservationDtoCopyWith(_ReservationDto value, $Res Function(_ReservationDto) _then) = __$ReservationDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String? eventId, String? userId, String? organizerId, String userName, String userEmail, String eventTitle,@TimestampConverter() DateTime eventStartsAt, String eventLocation,@JsonKey(unknownEnumValue: ReservationStatus.cancelled) ReservationStatus status,@TimestampConverter() DateTime reservedAt,@NullableTimestampConverter() DateTime? cancelledAt, String? tierId, String? tierName, int pricePaid, int? amountDue, String? currency, String? paymentStatus, String? checkoutUrl,@NullableTimestampConverter() DateTime? holdExpiresAt
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? eventId = freezed,Object? userId = freezed,Object? organizerId = freezed,Object? userName = null,Object? userEmail = null,Object? eventTitle = null,Object? eventStartsAt = null,Object? eventLocation = null,Object? status = null,Object? reservedAt = null,Object? cancelledAt = freezed,Object? tierId = freezed,Object? tierName = freezed,Object? pricePaid = null,Object? amountDue = freezed,Object? currency = freezed,Object? paymentStatus = freezed,Object? checkoutUrl = freezed,Object? holdExpiresAt = freezed,}) {
  return _then(_ReservationDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,eventId: freezed == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String?,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,organizerId: freezed == organizerId ? _self.organizerId : organizerId // ignore: cast_nullable_to_non_nullable
as String?,userName: null == userName ? _self.userName : userName // ignore: cast_nullable_to_non_nullable
as String,userEmail: null == userEmail ? _self.userEmail : userEmail // ignore: cast_nullable_to_non_nullable
as String,eventTitle: null == eventTitle ? _self.eventTitle : eventTitle // ignore: cast_nullable_to_non_nullable
as String,eventStartsAt: null == eventStartsAt ? _self.eventStartsAt : eventStartsAt // ignore: cast_nullable_to_non_nullable
as DateTime,eventLocation: null == eventLocation ? _self.eventLocation : eventLocation // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ReservationStatus,reservedAt: null == reservedAt ? _self.reservedAt : reservedAt // ignore: cast_nullable_to_non_nullable
as DateTime,cancelledAt: freezed == cancelledAt ? _self.cancelledAt : cancelledAt // ignore: cast_nullable_to_non_nullable
as DateTime?,tierId: freezed == tierId ? _self.tierId : tierId // ignore: cast_nullable_to_non_nullable
as String?,tierName: freezed == tierName ? _self.tierName : tierName // ignore: cast_nullable_to_non_nullable
as String?,pricePaid: null == pricePaid ? _self.pricePaid : pricePaid // ignore: cast_nullable_to_non_nullable
as int,amountDue: freezed == amountDue ? _self.amountDue : amountDue // ignore: cast_nullable_to_non_nullable
as int?,currency: freezed == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String?,paymentStatus: freezed == paymentStatus ? _self.paymentStatus : paymentStatus // ignore: cast_nullable_to_non_nullable
as String?,checkoutUrl: freezed == checkoutUrl ? _self.checkoutUrl : checkoutUrl // ignore: cast_nullable_to_non_nullable
as String?,holdExpiresAt: freezed == holdExpiresAt ? _self.holdExpiresAt : holdExpiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
