// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'check_in_result_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CheckInResultDto {

 String get status; String? get reservationId; String? get userName; String? get tierName;@NullableTimestampConverter() DateTime? get scannedAt;
/// Create a copy of CheckInResultDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CheckInResultDtoCopyWith<CheckInResultDto> get copyWith => _$CheckInResultDtoCopyWithImpl<CheckInResultDto>(this as CheckInResultDto, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CheckInResultDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CheckInResultDto&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.reservationId, _this.reservationId) || other.reservationId == _this.reservationId)&&(identical(other.userName, _this.userName) || other.userName == _this.userName)&&(identical(other.tierName, _this.tierName) || other.tierName == _this.tierName)&&(identical(other.scannedAt, _this.scannedAt) || other.scannedAt == _this.scannedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CheckInResultDto;
  return Object.hash(runtimeType,_this.status,_this.reservationId,_this.userName,_this.tierName,_this.scannedAt);
}

@override
String toString() {
  final _this = this as CheckInResultDto;
  return 'CheckInResultDto(status: ${_this.status}, reservationId: ${_this.reservationId}, userName: ${_this.userName}, tierName: ${_this.tierName}, scannedAt: ${_this.scannedAt})';
}


}

/// @nodoc
abstract mixin class $CheckInResultDtoCopyWith<$Res>  {
  factory $CheckInResultDtoCopyWith(CheckInResultDto value, $Res Function(CheckInResultDto) _then) = _$CheckInResultDtoCopyWithImpl;
@useResult
$Res call({
 String status, String? reservationId, String? userName, String? tierName,@NullableTimestampConverter() DateTime? scannedAt
});




}
/// @nodoc
class _$CheckInResultDtoCopyWithImpl<$Res>
    implements $CheckInResultDtoCopyWith<$Res> {
  _$CheckInResultDtoCopyWithImpl(this._self, this._then);

  final CheckInResultDto _self;
  final $Res Function(CheckInResultDto) _then;

/// Create a copy of CheckInResultDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? reservationId = freezed,Object? userName = freezed,Object? tierName = freezed,Object? scannedAt = freezed,}) {
  return _then(CheckInResultDto(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,reservationId: freezed == reservationId ? _self.reservationId : reservationId // ignore: cast_nullable_to_non_nullable
as String?,userName: freezed == userName ? _self.userName : userName // ignore: cast_nullable_to_non_nullable
as String?,tierName: freezed == tierName ? _self.tierName : tierName // ignore: cast_nullable_to_non_nullable
as String?,scannedAt: freezed == scannedAt ? _self.scannedAt : scannedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [CheckInResultDto].
extension CheckInResultDtoPatterns on CheckInResultDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CheckInResultDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CheckInResultDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CheckInResultDto value)  $default,){
final _that = this;
switch (_that) {
case _CheckInResultDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CheckInResultDto value)?  $default,){
final _that = this;
switch (_that) {
case _CheckInResultDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String status,  String? reservationId,  String? userName,  String? tierName, @NullableTimestampConverter()  DateTime? scannedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CheckInResultDto() when $default != null:
return $default(_that.status,_that.reservationId,_that.userName,_that.tierName,_that.scannedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String status,  String? reservationId,  String? userName,  String? tierName, @NullableTimestampConverter()  DateTime? scannedAt)  $default,) {final _that = this;
switch (_that) {
case _CheckInResultDto():
return $default(_that.status,_that.reservationId,_that.userName,_that.tierName,_that.scannedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String status,  String? reservationId,  String? userName,  String? tierName, @NullableTimestampConverter()  DateTime? scannedAt)?  $default,) {final _that = this;
switch (_that) {
case _CheckInResultDto() when $default != null:
return $default(_that.status,_that.reservationId,_that.userName,_that.tierName,_that.scannedAt);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class _CheckInResultDto extends CheckInResultDto {
  const _CheckInResultDto({required this.status, this.reservationId, this.userName, this.tierName, @NullableTimestampConverter() this.scannedAt}): super._();
  factory _CheckInResultDto.fromJson(Map<String, dynamic> json) => _$CheckInResultDtoFromJson(json);

@override final  String status;
@override final  String? reservationId;
@override final  String? userName;
@override final  String? tierName;
@override@NullableTimestampConverter() final  DateTime? scannedAt;

/// Create a copy of CheckInResultDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CheckInResultDtoCopyWith<_CheckInResultDto> get copyWith => __$CheckInResultDtoCopyWithImpl<_CheckInResultDto>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CheckInResultDto&&(identical(other.status, status) || other.status == status)&&(identical(other.reservationId, reservationId) || other.reservationId == reservationId)&&(identical(other.userName, userName) || other.userName == userName)&&(identical(other.tierName, tierName) || other.tierName == tierName)&&(identical(other.scannedAt, scannedAt) || other.scannedAt == scannedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,status,reservationId,userName,tierName,scannedAt);
}

@override
String toString() {
    return 'CheckInResultDto(status: $status, reservationId: $reservationId, userName: $userName, tierName: $tierName, scannedAt: $scannedAt)';
}


}

/// @nodoc
abstract mixin class _$CheckInResultDtoCopyWith<$Res> implements $CheckInResultDtoCopyWith<$Res> {
  factory _$CheckInResultDtoCopyWith(_CheckInResultDto value, $Res Function(_CheckInResultDto) _then) = __$CheckInResultDtoCopyWithImpl;
@override @useResult
$Res call({
 String status, String? reservationId, String? userName, String? tierName,@NullableTimestampConverter() DateTime? scannedAt
});




}
/// @nodoc
class __$CheckInResultDtoCopyWithImpl<$Res>
    implements _$CheckInResultDtoCopyWith<$Res> {
  __$CheckInResultDtoCopyWithImpl(this._self, this._then);

  final _CheckInResultDto _self;
  final $Res Function(_CheckInResultDto) _then;

/// Create a copy of CheckInResultDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? reservationId = freezed,Object? userName = freezed,Object? tierName = freezed,Object? scannedAt = freezed,}) {
  return _then(_CheckInResultDto(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,reservationId: freezed == reservationId ? _self.reservationId : reservationId // ignore: cast_nullable_to_non_nullable
as String?,userName: freezed == userName ? _self.userName : userName // ignore: cast_nullable_to_non_nullable
as String?,tierName: freezed == tierName ? _self.tierName : tierName // ignore: cast_nullable_to_non_nullable
as String?,scannedAt: freezed == scannedAt ? _self.scannedAt : scannedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
