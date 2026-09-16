// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserDto {

 String get name; String get email;@JsonKey(unknownEnumValue: UserRole.participant) UserRole get role;/// `null` dans le snapshot local en attente d’une inscription toute
/// fraîche.
@NullableTimestampConverter() DateTime? get createdAt; String? get bio;/// Photo de profil et photo de couverture.
///
/// Une URL `https:`, ou une image encodée dans le document lui-même
/// (`data:`) : sans Cloud Storage sur le plan Spark, c'est Firestore qui
/// porte l'image. Voir `ImageDataUrl` pour les bornes de taille.
 String? get photoUrl; String? get coverUrl;/// Posé par la modération : le compte lit mais ne peut plus écrire.
 bool get suspended;/// Horodaté au moment où la notification de bienvenue a été écrite.
@NullableTimestampConverter() DateTime? get welcomedAt;
/// Create a copy of UserDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserDtoCopyWith<UserDto> get copyWith => _$UserDtoCopyWithImpl<UserDto>(this as UserDto, _$identity);

  /// Serializes this UserDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as UserDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserDto&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.email, _this.email) || other.email == _this.email)&&(identical(other.role, _this.role) || other.role == _this.role)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.bio, _this.bio) || other.bio == _this.bio)&&(identical(other.photoUrl, _this.photoUrl) || other.photoUrl == _this.photoUrl)&&(identical(other.coverUrl, _this.coverUrl) || other.coverUrl == _this.coverUrl)&&(identical(other.suspended, _this.suspended) || other.suspended == _this.suspended)&&(identical(other.welcomedAt, _this.welcomedAt) || other.welcomedAt == _this.welcomedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as UserDto;
  return Object.hash(runtimeType,_this.name,_this.email,_this.role,_this.createdAt,_this.bio,_this.photoUrl,_this.coverUrl,_this.suspended,_this.welcomedAt);
}

@override
String toString() {
  final _this = this as UserDto;
  return 'UserDto(name: ${_this.name}, email: ${_this.email}, role: ${_this.role}, createdAt: ${_this.createdAt}, bio: ${_this.bio}, photoUrl: ${_this.photoUrl}, coverUrl: ${_this.coverUrl}, suspended: ${_this.suspended}, welcomedAt: ${_this.welcomedAt})';
}


}

/// @nodoc
abstract mixin class $UserDtoCopyWith<$Res>  {
  factory $UserDtoCopyWith(UserDto value, $Res Function(UserDto) _then) = _$UserDtoCopyWithImpl;
@useResult
$Res call({
 String name, String email,@JsonKey(unknownEnumValue: UserRole.participant) UserRole role,@NullableTimestampConverter() DateTime? createdAt, String? bio, String? photoUrl, String? coverUrl, bool suspended,@NullableTimestampConverter() DateTime? welcomedAt
});




}
/// @nodoc
class _$UserDtoCopyWithImpl<$Res>
    implements $UserDtoCopyWith<$Res> {
  _$UserDtoCopyWithImpl(this._self, this._then);

  final UserDto _self;
  final $Res Function(UserDto) _then;

/// Create a copy of UserDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? email = null,Object? role = null,Object? createdAt = freezed,Object? bio = freezed,Object? photoUrl = freezed,Object? coverUrl = freezed,Object? suspended = null,Object? welcomedAt = freezed,}) {
  return _then(UserDto(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as UserRole,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,suspended: null == suspended ? _self.suspended : suspended // ignore: cast_nullable_to_non_nullable
as bool,welcomedAt: freezed == welcomedAt ? _self.welcomedAt : welcomedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [UserDto].
extension UserDtoPatterns on UserDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserDto value)  $default,){
final _that = this;
switch (_that) {
case _UserDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserDto value)?  $default,){
final _that = this;
switch (_that) {
case _UserDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String email, @JsonKey(unknownEnumValue: UserRole.participant)  UserRole role, @NullableTimestampConverter()  DateTime? createdAt,  String? bio,  String? photoUrl,  String? coverUrl,  bool suspended, @NullableTimestampConverter()  DateTime? welcomedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserDto() when $default != null:
return $default(_that.name,_that.email,_that.role,_that.createdAt,_that.bio,_that.photoUrl,_that.coverUrl,_that.suspended,_that.welcomedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String email, @JsonKey(unknownEnumValue: UserRole.participant)  UserRole role, @NullableTimestampConverter()  DateTime? createdAt,  String? bio,  String? photoUrl,  String? coverUrl,  bool suspended, @NullableTimestampConverter()  DateTime? welcomedAt)  $default,) {final _that = this;
switch (_that) {
case _UserDto():
return $default(_that.name,_that.email,_that.role,_that.createdAt,_that.bio,_that.photoUrl,_that.coverUrl,_that.suspended,_that.welcomedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String email, @JsonKey(unknownEnumValue: UserRole.participant)  UserRole role, @NullableTimestampConverter()  DateTime? createdAt,  String? bio,  String? photoUrl,  String? coverUrl,  bool suspended, @NullableTimestampConverter()  DateTime? welcomedAt)?  $default,) {final _that = this;
switch (_that) {
case _UserDto() when $default != null:
return $default(_that.name,_that.email,_that.role,_that.createdAt,_that.bio,_that.photoUrl,_that.coverUrl,_that.suspended,_that.welcomedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserDto extends UserDto {
  const _UserDto({required this.name, required this.email, @JsonKey(unknownEnumValue: UserRole.participant) required this.role, @NullableTimestampConverter() this.createdAt, this.bio, this.photoUrl, this.coverUrl, this.suspended = false, @NullableTimestampConverter() this.welcomedAt}): super._();
  factory _UserDto.fromJson(Map<String, dynamic> json) => _$UserDtoFromJson(json);

@override final  String name;
@override final  String email;
@override@JsonKey(unknownEnumValue: UserRole.participant) final  UserRole role;
/// `null` dans le snapshot local en attente d’une inscription toute
/// fraîche.
@override@NullableTimestampConverter() final  DateTime? createdAt;
@override final  String? bio;
/// Photo de profil et photo de couverture.
///
/// Une URL `https:`, ou une image encodée dans le document lui-même
/// (`data:`) : sans Cloud Storage sur le plan Spark, c'est Firestore qui
/// porte l'image. Voir `ImageDataUrl` pour les bornes de taille.
@override final  String? photoUrl;
@override final  String? coverUrl;
/// Posé par la modération : le compte lit mais ne peut plus écrire.
@override@JsonKey() final  bool suspended;
/// Horodaté au moment où la notification de bienvenue a été écrite.
@override@NullableTimestampConverter() final  DateTime? welcomedAt;

/// Create a copy of UserDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserDtoCopyWith<_UserDto> get copyWith => __$UserDtoCopyWithImpl<_UserDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserDto&&(identical(other.name, name) || other.name == name)&&(identical(other.email, email) || other.email == email)&&(identical(other.role, role) || other.role == role)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.coverUrl, coverUrl) || other.coverUrl == coverUrl)&&(identical(other.suspended, suspended) || other.suspended == suspended)&&(identical(other.welcomedAt, welcomedAt) || other.welcomedAt == welcomedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,name,email,role,createdAt,bio,photoUrl,coverUrl,suspended,welcomedAt);
}

@override
String toString() {
    return 'UserDto(name: $name, email: $email, role: $role, createdAt: $createdAt, bio: $bio, photoUrl: $photoUrl, coverUrl: $coverUrl, suspended: $suspended, welcomedAt: $welcomedAt)';
}


}

/// @nodoc
abstract mixin class _$UserDtoCopyWith<$Res> implements $UserDtoCopyWith<$Res> {
  factory _$UserDtoCopyWith(_UserDto value, $Res Function(_UserDto) _then) = __$UserDtoCopyWithImpl;
@override @useResult
$Res call({
 String name, String email,@JsonKey(unknownEnumValue: UserRole.participant) UserRole role,@NullableTimestampConverter() DateTime? createdAt, String? bio, String? photoUrl, String? coverUrl, bool suspended,@NullableTimestampConverter() DateTime? welcomedAt
});




}
/// @nodoc
class __$UserDtoCopyWithImpl<$Res>
    implements _$UserDtoCopyWith<$Res> {
  __$UserDtoCopyWithImpl(this._self, this._then);

  final _UserDto _self;
  final $Res Function(_UserDto) _then;

/// Create a copy of UserDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? email = null,Object? role = null,Object? createdAt = freezed,Object? bio = freezed,Object? photoUrl = freezed,Object? coverUrl = freezed,Object? suspended = null,Object? welcomedAt = freezed,}) {
  return _then(_UserDto(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as UserRole,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,suspended: null == suspended ? _self.suspended : suspended // ignore: cast_nullable_to_non_nullable
as bool,welcomedAt: freezed == welcomedAt ? _self.welcomedAt : welcomedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
