// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'notification_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$NotificationDto {

 String get id; String get type; String get title; String get body;@JsonKey(name: 'event_id') String? get eventId;@JsonKey(name: 'reservation_id') String? get reservationId;@JsonKey(name: 'created_at')@TimestampConverter() DateTime get createdAt;@JsonKey(name: 'read_at')@NullableTimestampConverter() DateTime? get readAt;/// Purged by pg_cron after 30 days; filtered client-side in between so
/// a row past its date never shows while the purge has not run yet.
@JsonKey(name: 'expires_at')@NullableTimestampConverter() DateTime? get expiresAt;
/// Create a copy of NotificationDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NotificationDtoCopyWith<NotificationDto> get copyWith => _$NotificationDtoCopyWithImpl<NotificationDto>(this as NotificationDto, _$identity);

  /// Serializes this NotificationDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as NotificationDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NotificationDto&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.body, _this.body) || other.body == _this.body)&&(identical(other.eventId, _this.eventId) || other.eventId == _this.eventId)&&(identical(other.reservationId, _this.reservationId) || other.reservationId == _this.reservationId)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.readAt, _this.readAt) || other.readAt == _this.readAt)&&(identical(other.expiresAt, _this.expiresAt) || other.expiresAt == _this.expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as NotificationDto;
  return Object.hash(runtimeType,_this.id,_this.type,_this.title,_this.body,_this.eventId,_this.reservationId,_this.createdAt,_this.readAt,_this.expiresAt);
}

@override
String toString() {
  final _this = this as NotificationDto;
  return 'NotificationDto(id: ${_this.id}, type: ${_this.type}, title: ${_this.title}, body: ${_this.body}, eventId: ${_this.eventId}, reservationId: ${_this.reservationId}, createdAt: ${_this.createdAt}, readAt: ${_this.readAt}, expiresAt: ${_this.expiresAt})';
}


}

/// @nodoc
abstract mixin class $NotificationDtoCopyWith<$Res>  {
  factory $NotificationDtoCopyWith(NotificationDto value, $Res Function(NotificationDto) _then) = _$NotificationDtoCopyWithImpl;
@useResult
$Res call({
 String id, String type, String title, String body,@JsonKey(name: 'event_id') String? eventId,@JsonKey(name: 'reservation_id') String? reservationId,@JsonKey(name: 'created_at')@TimestampConverter() DateTime createdAt,@JsonKey(name: 'read_at')@NullableTimestampConverter() DateTime? readAt,@JsonKey(name: 'expires_at')@NullableTimestampConverter() DateTime? expiresAt
});




}
/// @nodoc
class _$NotificationDtoCopyWithImpl<$Res>
    implements $NotificationDtoCopyWith<$Res> {
  _$NotificationDtoCopyWithImpl(this._self, this._then);

  final NotificationDto _self;
  final $Res Function(NotificationDto) _then;

/// Create a copy of NotificationDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? title = null,Object? body = null,Object? eventId = freezed,Object? reservationId = freezed,Object? createdAt = null,Object? readAt = freezed,Object? expiresAt = freezed,}) {
  return _then(NotificationDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,eventId: freezed == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String?,reservationId: freezed == reservationId ? _self.reservationId : reservationId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,readAt: freezed == readAt ? _self.readAt : readAt // ignore: cast_nullable_to_non_nullable
as DateTime?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [NotificationDto].
extension NotificationDtoPatterns on NotificationDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NotificationDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NotificationDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NotificationDto value)  $default,){
final _that = this;
switch (_that) {
case _NotificationDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NotificationDto value)?  $default,){
final _that = this;
switch (_that) {
case _NotificationDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String type,  String title,  String body, @JsonKey(name: 'event_id')  String? eventId, @JsonKey(name: 'reservation_id')  String? reservationId, @JsonKey(name: 'created_at')@TimestampConverter()  DateTime createdAt, @JsonKey(name: 'read_at')@NullableTimestampConverter()  DateTime? readAt, @JsonKey(name: 'expires_at')@NullableTimestampConverter()  DateTime? expiresAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NotificationDto() when $default != null:
return $default(_that.id,_that.type,_that.title,_that.body,_that.eventId,_that.reservationId,_that.createdAt,_that.readAt,_that.expiresAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String type,  String title,  String body, @JsonKey(name: 'event_id')  String? eventId, @JsonKey(name: 'reservation_id')  String? reservationId, @JsonKey(name: 'created_at')@TimestampConverter()  DateTime createdAt, @JsonKey(name: 'read_at')@NullableTimestampConverter()  DateTime? readAt, @JsonKey(name: 'expires_at')@NullableTimestampConverter()  DateTime? expiresAt)  $default,) {final _that = this;
switch (_that) {
case _NotificationDto():
return $default(_that.id,_that.type,_that.title,_that.body,_that.eventId,_that.reservationId,_that.createdAt,_that.readAt,_that.expiresAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String type,  String title,  String body, @JsonKey(name: 'event_id')  String? eventId, @JsonKey(name: 'reservation_id')  String? reservationId, @JsonKey(name: 'created_at')@TimestampConverter()  DateTime createdAt, @JsonKey(name: 'read_at')@NullableTimestampConverter()  DateTime? readAt, @JsonKey(name: 'expires_at')@NullableTimestampConverter()  DateTime? expiresAt)?  $default,) {final _that = this;
switch (_that) {
case _NotificationDto() when $default != null:
return $default(_that.id,_that.type,_that.title,_that.body,_that.eventId,_that.reservationId,_that.createdAt,_that.readAt,_that.expiresAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NotificationDto extends NotificationDto {
  const _NotificationDto({required this.id, required this.type, this.title = '', this.body = '', @JsonKey(name: 'event_id') this.eventId, @JsonKey(name: 'reservation_id') this.reservationId, @JsonKey(name: 'created_at')@TimestampConverter() required this.createdAt, @JsonKey(name: 'read_at')@NullableTimestampConverter() this.readAt, @JsonKey(name: 'expires_at')@NullableTimestampConverter() this.expiresAt}): super._();
  factory _NotificationDto.fromJson(Map<String, dynamic> json) => _$NotificationDtoFromJson(json);

@override final  String id;
@override final  String type;
@override@JsonKey() final  String title;
@override@JsonKey() final  String body;
@override@JsonKey(name: 'event_id') final  String? eventId;
@override@JsonKey(name: 'reservation_id') final  String? reservationId;
@override@JsonKey(name: 'created_at')@TimestampConverter() final  DateTime createdAt;
@override@JsonKey(name: 'read_at')@NullableTimestampConverter() final  DateTime? readAt;
/// Purged by pg_cron after 30 days; filtered client-side in between so
/// a row past its date never shows while the purge has not run yet.
@override@JsonKey(name: 'expires_at')@NullableTimestampConverter() final  DateTime? expiresAt;

/// Create a copy of NotificationDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NotificationDtoCopyWith<_NotificationDto> get copyWith => __$NotificationDtoCopyWithImpl<_NotificationDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NotificationDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _NotificationDto&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.title, title) || other.title == title)&&(identical(other.body, body) || other.body == body)&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.reservationId, reservationId) || other.reservationId == reservationId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.readAt, readAt) || other.readAt == readAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,type,title,body,eventId,reservationId,createdAt,readAt,expiresAt);
}

@override
String toString() {
    return 'NotificationDto(id: $id, type: $type, title: $title, body: $body, eventId: $eventId, reservationId: $reservationId, createdAt: $createdAt, readAt: $readAt, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class _$NotificationDtoCopyWith<$Res> implements $NotificationDtoCopyWith<$Res> {
  factory _$NotificationDtoCopyWith(_NotificationDto value, $Res Function(_NotificationDto) _then) = __$NotificationDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String type, String title, String body,@JsonKey(name: 'event_id') String? eventId,@JsonKey(name: 'reservation_id') String? reservationId,@JsonKey(name: 'created_at')@TimestampConverter() DateTime createdAt,@JsonKey(name: 'read_at')@NullableTimestampConverter() DateTime? readAt,@JsonKey(name: 'expires_at')@NullableTimestampConverter() DateTime? expiresAt
});




}
/// @nodoc
class __$NotificationDtoCopyWithImpl<$Res>
    implements _$NotificationDtoCopyWith<$Res> {
  __$NotificationDtoCopyWithImpl(this._self, this._then);

  final _NotificationDto _self;
  final $Res Function(_NotificationDto) _then;

/// Create a copy of NotificationDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? title = null,Object? body = null,Object? eventId = freezed,Object? reservationId = freezed,Object? createdAt = null,Object? readAt = freezed,Object? expiresAt = freezed,}) {
  return _then(_NotificationDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,eventId: freezed == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String?,reservationId: freezed == reservationId ? _self.reservationId : reservationId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,readAt: freezed == readAt ? _self.readAt : readAt // ignore: cast_nullable_to_non_nullable
as DateTime?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$NotificationPreferencesDto {

@JsonKey(name: 'event_reminders') bool get eventReminders;@JsonKey(name: 'booking_alerts') bool get bookingAlerts;@JsonKey(name: 'followed_organizers') bool get followedOrganizers;
/// Create a copy of NotificationPreferencesDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NotificationPreferencesDtoCopyWith<NotificationPreferencesDto> get copyWith => _$NotificationPreferencesDtoCopyWithImpl<NotificationPreferencesDto>(this as NotificationPreferencesDto, _$identity);

  /// Serializes this NotificationPreferencesDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as NotificationPreferencesDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NotificationPreferencesDto&&(identical(other.eventReminders, _this.eventReminders) || other.eventReminders == _this.eventReminders)&&(identical(other.bookingAlerts, _this.bookingAlerts) || other.bookingAlerts == _this.bookingAlerts)&&(identical(other.followedOrganizers, _this.followedOrganizers) || other.followedOrganizers == _this.followedOrganizers));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as NotificationPreferencesDto;
  return Object.hash(runtimeType,_this.eventReminders,_this.bookingAlerts,_this.followedOrganizers);
}

@override
String toString() {
  final _this = this as NotificationPreferencesDto;
  return 'NotificationPreferencesDto(eventReminders: ${_this.eventReminders}, bookingAlerts: ${_this.bookingAlerts}, followedOrganizers: ${_this.followedOrganizers})';
}


}

/// @nodoc
abstract mixin class $NotificationPreferencesDtoCopyWith<$Res>  {
  factory $NotificationPreferencesDtoCopyWith(NotificationPreferencesDto value, $Res Function(NotificationPreferencesDto) _then) = _$NotificationPreferencesDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'event_reminders') bool eventReminders,@JsonKey(name: 'booking_alerts') bool bookingAlerts,@JsonKey(name: 'followed_organizers') bool followedOrganizers
});




}
/// @nodoc
class _$NotificationPreferencesDtoCopyWithImpl<$Res>
    implements $NotificationPreferencesDtoCopyWith<$Res> {
  _$NotificationPreferencesDtoCopyWithImpl(this._self, this._then);

  final NotificationPreferencesDto _self;
  final $Res Function(NotificationPreferencesDto) _then;

/// Create a copy of NotificationPreferencesDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? eventReminders = null,Object? bookingAlerts = null,Object? followedOrganizers = null,}) {
  return _then(NotificationPreferencesDto(
eventReminders: null == eventReminders ? _self.eventReminders : eventReminders // ignore: cast_nullable_to_non_nullable
as bool,bookingAlerts: null == bookingAlerts ? _self.bookingAlerts : bookingAlerts // ignore: cast_nullable_to_non_nullable
as bool,followedOrganizers: null == followedOrganizers ? _self.followedOrganizers : followedOrganizers // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [NotificationPreferencesDto].
extension NotificationPreferencesDtoPatterns on NotificationPreferencesDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NotificationPreferencesDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NotificationPreferencesDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NotificationPreferencesDto value)  $default,){
final _that = this;
switch (_that) {
case _NotificationPreferencesDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NotificationPreferencesDto value)?  $default,){
final _that = this;
switch (_that) {
case _NotificationPreferencesDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'event_reminders')  bool eventReminders, @JsonKey(name: 'booking_alerts')  bool bookingAlerts, @JsonKey(name: 'followed_organizers')  bool followedOrganizers)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NotificationPreferencesDto() when $default != null:
return $default(_that.eventReminders,_that.bookingAlerts,_that.followedOrganizers);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'event_reminders')  bool eventReminders, @JsonKey(name: 'booking_alerts')  bool bookingAlerts, @JsonKey(name: 'followed_organizers')  bool followedOrganizers)  $default,) {final _that = this;
switch (_that) {
case _NotificationPreferencesDto():
return $default(_that.eventReminders,_that.bookingAlerts,_that.followedOrganizers);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'event_reminders')  bool eventReminders, @JsonKey(name: 'booking_alerts')  bool bookingAlerts, @JsonKey(name: 'followed_organizers')  bool followedOrganizers)?  $default,) {final _that = this;
switch (_that) {
case _NotificationPreferencesDto() when $default != null:
return $default(_that.eventReminders,_that.bookingAlerts,_that.followedOrganizers);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NotificationPreferencesDto extends NotificationPreferencesDto {
  const _NotificationPreferencesDto({@JsonKey(name: 'event_reminders') this.eventReminders = true, @JsonKey(name: 'booking_alerts') this.bookingAlerts = true, @JsonKey(name: 'followed_organizers') this.followedOrganizers = true}): super._();
  factory _NotificationPreferencesDto.fromJson(Map<String, dynamic> json) => _$NotificationPreferencesDtoFromJson(json);

@override@JsonKey(name: 'event_reminders') final  bool eventReminders;
@override@JsonKey(name: 'booking_alerts') final  bool bookingAlerts;
@override@JsonKey(name: 'followed_organizers') final  bool followedOrganizers;

/// Create a copy of NotificationPreferencesDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NotificationPreferencesDtoCopyWith<_NotificationPreferencesDto> get copyWith => __$NotificationPreferencesDtoCopyWithImpl<_NotificationPreferencesDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NotificationPreferencesDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _NotificationPreferencesDto&&(identical(other.eventReminders, eventReminders) || other.eventReminders == eventReminders)&&(identical(other.bookingAlerts, bookingAlerts) || other.bookingAlerts == bookingAlerts)&&(identical(other.followedOrganizers, followedOrganizers) || other.followedOrganizers == followedOrganizers));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,eventReminders,bookingAlerts,followedOrganizers);
}

@override
String toString() {
    return 'NotificationPreferencesDto(eventReminders: $eventReminders, bookingAlerts: $bookingAlerts, followedOrganizers: $followedOrganizers)';
}


}

/// @nodoc
abstract mixin class _$NotificationPreferencesDtoCopyWith<$Res> implements $NotificationPreferencesDtoCopyWith<$Res> {
  factory _$NotificationPreferencesDtoCopyWith(_NotificationPreferencesDto value, $Res Function(_NotificationPreferencesDto) _then) = __$NotificationPreferencesDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'event_reminders') bool eventReminders,@JsonKey(name: 'booking_alerts') bool bookingAlerts,@JsonKey(name: 'followed_organizers') bool followedOrganizers
});




}
/// @nodoc
class __$NotificationPreferencesDtoCopyWithImpl<$Res>
    implements _$NotificationPreferencesDtoCopyWith<$Res> {
  __$NotificationPreferencesDtoCopyWithImpl(this._self, this._then);

  final _NotificationPreferencesDto _self;
  final $Res Function(_NotificationPreferencesDto) _then;

/// Create a copy of NotificationPreferencesDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? eventReminders = null,Object? bookingAlerts = null,Object? followedOrganizers = null,}) {
  return _then(_NotificationPreferencesDto(
eventReminders: null == eventReminders ? _self.eventReminders : eventReminders // ignore: cast_nullable_to_non_nullable
as bool,bookingAlerts: null == bookingAlerts ? _self.bookingAlerts : bookingAlerts // ignore: cast_nullable_to_non_nullable
as bool,followedOrganizers: null == followedOrganizers ? _self.followedOrganizers : followedOrganizers // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
