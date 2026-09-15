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
  createdAt: const NullableTimestampConverter().fromJson(json['created_at']),
  bio: json['bio'] as String?,
);

Map<String, dynamic> _$UserDtoToJson(_UserDto instance) => <String, dynamic>{
  'name': instance.name,
  'email': instance.email,
  'role': _$UserRoleEnumMap[instance.role]!,
  'created_at': const NullableTimestampConverter().toJson(instance.createdAt),
  'bio': instance.bio,
};

const _$UserRoleEnumMap = {
  UserRole.participant: 'participant',
  UserRole.organizer: 'organizer',
};
