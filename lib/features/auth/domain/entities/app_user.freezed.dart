// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_user.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AppUser {

 String get id; String get name; String get email; UserRole get role; DateTime? get createdAt;/// Organisateurs uniquement : la présentation publiée sur leur profil
/// public.
 String? get bio;/// Photo de profil, et bandeau de couverture du profil.
///
/// Chaîne unique pour deux provenances : une URL `https:` ou une image
/// `data:` embarquée dans le document Firestore. Tout ce qui les affiche
/// n'a donc qu'un cas à traiter — une URL.
 String? get photoUrl; String? get coverUrl;/// Lu depuis Firebase Auth, jamais stocké dans Firestore : c’est au claim
/// `email_verified` du token que les règles de sécurité se fient.
 bool get emailVerified;/// Le custom claim `admin`, lu depuis l’ID token — jamais depuis
/// Firestore, où personne ne pourrait être habilité à l’écrire. Il donne
/// accès à l’espace de modération ; le serveur revérifie le claim à
/// chaque appel.
 bool get isAdmin;/// Le rôle coché dans le formulaire d'inscription, conservé tel quel.
/// Égal à [role] pour tout compte récent — les deux rôles sont fixés à
/// l'inscription — ; `null` pour les comptes créés avant la question.
 UserRole? get intendedRole;
/// Create a copy of AppUser
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppUserCopyWith<AppUser> get copyWith => _$AppUserCopyWithImpl<AppUser>(this as AppUser, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AppUser;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppUser&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.email, _this.email) || other.email == _this.email)&&(identical(other.role, _this.role) || other.role == _this.role)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.bio, _this.bio) || other.bio == _this.bio)&&(identical(other.photoUrl, _this.photoUrl) || other.photoUrl == _this.photoUrl)&&(identical(other.coverUrl, _this.coverUrl) || other.coverUrl == _this.coverUrl)&&(identical(other.emailVerified, _this.emailVerified) || other.emailVerified == _this.emailVerified)&&(identical(other.isAdmin, _this.isAdmin) || other.isAdmin == _this.isAdmin)&&(identical(other.intendedRole, _this.intendedRole) || other.intendedRole == _this.intendedRole));
}


@override
int get hashCode {
  final _this = this as AppUser;
  return Object.hash(runtimeType,_this.id,_this.name,_this.email,_this.role,_this.createdAt,_this.bio,_this.photoUrl,_this.coverUrl,_this.emailVerified,_this.isAdmin,_this.intendedRole);
}

@override
String toString() {
  final _this = this as AppUser;
  return 'AppUser(id: ${_this.id}, name: ${_this.name}, email: ${_this.email}, role: ${_this.role}, createdAt: ${_this.createdAt}, bio: ${_this.bio}, photoUrl: ${_this.photoUrl}, coverUrl: ${_this.coverUrl}, emailVerified: ${_this.emailVerified}, isAdmin: ${_this.isAdmin}, intendedRole: ${_this.intendedRole})';
}


}

/// @nodoc
abstract mixin class $AppUserCopyWith<$Res>  {
  factory $AppUserCopyWith(AppUser value, $Res Function(AppUser) _then) = _$AppUserCopyWithImpl;
@useResult
$Res call({
 String id, String name, String email, UserRole role, DateTime? createdAt, String? bio, String? photoUrl, String? coverUrl, bool emailVerified, bool isAdmin, UserRole? intendedRole
});




}
/// @nodoc
class _$AppUserCopyWithImpl<$Res>
    implements $AppUserCopyWith<$Res> {
  _$AppUserCopyWithImpl(this._self, this._then);

  final AppUser _self;
  final $Res Function(AppUser) _then;

/// Create a copy of AppUser
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? email = null,Object? role = null,Object? createdAt = freezed,Object? bio = freezed,Object? photoUrl = freezed,Object? coverUrl = freezed,Object? emailVerified = null,Object? isAdmin = null,Object? intendedRole = freezed,}) {
  return _then(AppUser(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as UserRole,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,emailVerified: null == emailVerified ? _self.emailVerified : emailVerified // ignore: cast_nullable_to_non_nullable
as bool,isAdmin: null == isAdmin ? _self.isAdmin : isAdmin // ignore: cast_nullable_to_non_nullable
as bool,intendedRole: freezed == intendedRole ? _self.intendedRole : intendedRole // ignore: cast_nullable_to_non_nullable
as UserRole?,
  ));
}

}


/// Adds pattern-matching-related methods to [AppUser].
extension AppUserPatterns on AppUser {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppUser value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppUser() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppUser value)  $default,){
final _that = this;
switch (_that) {
case _AppUser():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppUser value)?  $default,){
final _that = this;
switch (_that) {
case _AppUser() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String email,  UserRole role,  DateTime? createdAt,  String? bio,  String? photoUrl,  String? coverUrl,  bool emailVerified,  bool isAdmin,  UserRole? intendedRole)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppUser() when $default != null:
return $default(_that.id,_that.name,_that.email,_that.role,_that.createdAt,_that.bio,_that.photoUrl,_that.coverUrl,_that.emailVerified,_that.isAdmin,_that.intendedRole);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String email,  UserRole role,  DateTime? createdAt,  String? bio,  String? photoUrl,  String? coverUrl,  bool emailVerified,  bool isAdmin,  UserRole? intendedRole)  $default,) {final _that = this;
switch (_that) {
case _AppUser():
return $default(_that.id,_that.name,_that.email,_that.role,_that.createdAt,_that.bio,_that.photoUrl,_that.coverUrl,_that.emailVerified,_that.isAdmin,_that.intendedRole);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String email,  UserRole role,  DateTime? createdAt,  String? bio,  String? photoUrl,  String? coverUrl,  bool emailVerified,  bool isAdmin,  UserRole? intendedRole)?  $default,) {final _that = this;
switch (_that) {
case _AppUser() when $default != null:
return $default(_that.id,_that.name,_that.email,_that.role,_that.createdAt,_that.bio,_that.photoUrl,_that.coverUrl,_that.emailVerified,_that.isAdmin,_that.intendedRole);case _:
  return null;

}
}

}

/// @nodoc


class _AppUser extends AppUser {
  const _AppUser({required this.id, required this.name, required this.email, required this.role, this.createdAt, this.bio, this.photoUrl, this.coverUrl, this.emailVerified = false, this.isAdmin = false, this.intendedRole}): super._();
  

@override final  String id;
@override final  String name;
@override final  String email;
@override final  UserRole role;
@override final  DateTime? createdAt;
/// Organisateurs uniquement : la présentation publiée sur leur profil
/// public.
@override final  String? bio;
/// Photo de profil, et bandeau de couverture du profil.
///
/// Chaîne unique pour deux provenances : une URL `https:` ou une image
/// `data:` embarquée dans le document Firestore. Tout ce qui les affiche
/// n'a donc qu'un cas à traiter — une URL.
@override final  String? photoUrl;
@override final  String? coverUrl;
/// Lu depuis Firebase Auth, jamais stocké dans Firestore : c’est au claim
/// `email_verified` du token que les règles de sécurité se fient.
@override@JsonKey() final  bool emailVerified;
/// Le custom claim `admin`, lu depuis l’ID token — jamais depuis
/// Firestore, où personne ne pourrait être habilité à l’écrire. Il donne
/// accès à l’espace de modération ; le serveur revérifie le claim à
/// chaque appel.
@override@JsonKey() final  bool isAdmin;
/// Le rôle coché dans le formulaire d'inscription, conservé tel quel.
/// Égal à [role] pour tout compte récent — les deux rôles sont fixés à
/// l'inscription — ; `null` pour les comptes créés avant la question.
@override final  UserRole? intendedRole;

/// Create a copy of AppUser
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppUserCopyWith<_AppUser> get copyWith => __$AppUserCopyWithImpl<_AppUser>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppUser&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.email, email) || other.email == email)&&(identical(other.role, role) || other.role == role)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.coverUrl, coverUrl) || other.coverUrl == coverUrl)&&(identical(other.emailVerified, emailVerified) || other.emailVerified == emailVerified)&&(identical(other.isAdmin, isAdmin) || other.isAdmin == isAdmin)&&(identical(other.intendedRole, intendedRole) || other.intendedRole == intendedRole));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,name,email,role,createdAt,bio,photoUrl,coverUrl,emailVerified,isAdmin,intendedRole);
}

@override
String toString() {
    return 'AppUser(id: $id, name: $name, email: $email, role: $role, createdAt: $createdAt, bio: $bio, photoUrl: $photoUrl, coverUrl: $coverUrl, emailVerified: $emailVerified, isAdmin: $isAdmin, intendedRole: $intendedRole)';
}


}

/// @nodoc
abstract mixin class _$AppUserCopyWith<$Res> implements $AppUserCopyWith<$Res> {
  factory _$AppUserCopyWith(_AppUser value, $Res Function(_AppUser) _then) = __$AppUserCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String email, UserRole role, DateTime? createdAt, String? bio, String? photoUrl, String? coverUrl, bool emailVerified, bool isAdmin, UserRole? intendedRole
});




}
/// @nodoc
class __$AppUserCopyWithImpl<$Res>
    implements _$AppUserCopyWith<$Res> {
  __$AppUserCopyWithImpl(this._self, this._then);

  final _AppUser _self;
  final $Res Function(_AppUser) _then;

/// Create a copy of AppUser
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? email = null,Object? role = null,Object? createdAt = freezed,Object? bio = freezed,Object? photoUrl = freezed,Object? coverUrl = freezed,Object? emailVerified = null,Object? isAdmin = null,Object? intendedRole = freezed,}) {
  return _then(_AppUser(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as UserRole,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,emailVerified: null == emailVerified ? _self.emailVerified : emailVerified // ignore: cast_nullable_to_non_nullable
as bool,isAdmin: null == isAdmin ? _self.isAdmin : isAdmin // ignore: cast_nullable_to_non_nullable
as bool,intendedRole: freezed == intendedRole ? _self.intendedRole : intendedRole // ignore: cast_nullable_to_non_nullable
as UserRole?,
  ));
}


}

// dart format on
