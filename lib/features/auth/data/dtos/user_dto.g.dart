// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserDto _$UserDtoFromJson(Map<String, dynamic> json) => _UserDto(
  name: json['name'] as String,
  email: json['email'] as String,
  role: $enumDecode(
    _$UserRoleEnumMap,
    json['role'],
    unknownValue: UserRole.participant,
  ),
  createdAt: const NullableTimestampConverter().fromJson(json['createdAt']),
  bio: json['bio'] as String?,
  photoUrl: json['photoUrl'] as String?,
  coverUrl: json['coverUrl'] as String?,
  suspended: json['suspended'] as bool? ?? false,
  welcomedAt: const NullableTimestampConverter().fromJson(json['welcomedAt']),
  intendedRole: $enumDecodeNullable(
    _$UserRoleEnumMap,
    json['intendedRole'],
    unknownValue: JsonKey.nullForUndefinedEnumValue,
  ),
);

Map<String, dynamic> _$UserDtoToJson(_UserDto instance) => <String, dynamic>{
  'name': instance.name,
  'email': instance.email,
  'role': _$UserRoleEnumMap[instance.role]!,
  'createdAt': const NullableTimestampConverter().toJson(instance.createdAt),
  'bio': instance.bio,
  'photoUrl': instance.photoUrl,
  'coverUrl': instance.coverUrl,
  'suspended': instance.suspended,
  'welcomedAt': const NullableTimestampConverter().toJson(instance.welcomedAt),
  'intendedRole': _$UserRoleEnumMap[instance.intendedRole],
};

const _$UserRoleEnumMap = {
  UserRole.participant: 'participant',
  UserRole.organizer: 'organizer',
};
