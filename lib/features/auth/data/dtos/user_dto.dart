import 'package:eventhub/core/firebase/timestamp_converter.dart';
import 'package:eventhub/features/auth/domain/entities/app_user.dart';
import 'package:eventhub/features/auth/domain/entities/user_role.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_dto.freezed.dart';
part 'user_dto.g.dart';

/// Firestore document `users/{uid}`. The id is the document id, never a field.
@freezed
abstract class UserDto with _$UserDto {
  const UserDto._();

  const factory UserDto({
    required String name,
    required String email,
    @JsonKey(unknownEnumValue: UserRole.participant) required UserRole role,
    @NullableTimestampConverter() DateTime? createdAt,
  }) = _UserDto;

  factory UserDto.fromJson(Map<String, dynamic> json) =>
      _$UserDtoFromJson(json);

  factory UserDto.fromDomain(AppUser user) => UserDto(
    name: user.name,
    email: user.email,
    role: user.role,
    createdAt: user.createdAt,
  );

  AppUser toDomain(String id) => AppUser(
    id: id,
    name: name,
    email: email,
    role: role,
    createdAt: createdAt,
  );
}
