import 'package:eventhub/core/supabase/timestamp_converter.dart';
import 'package:eventhub/features/auth/domain/entities/app_user.dart';
import 'package:eventhub/features/auth/domain/entities/user_role.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_dto.freezed.dart';
part 'user_dto.g.dart';

/// Row of `public.profiles`. The id is read separately by the repository.
@freezed
abstract class UserDto with _$UserDto {
  const UserDto._();

  const factory UserDto({
    required String name,
    required String email,
    @JsonKey(unknownEnumValue: UserRole.participant) required UserRole role,
    @JsonKey(name: 'created_at')
    @NullableTimestampConverter()
    DateTime? createdAt,

    /// Published on `organizers` by a trigger when the profile changes.
    String? bio,
  }) = _UserDto;

  factory UserDto.fromJson(Map<String, dynamic> json) =>
      _$UserDtoFromJson(json);

  factory UserDto.fromDomain(AppUser user) => UserDto(
    name: user.name,
    email: user.email,
    role: user.role,
    createdAt: user.createdAt,
    bio: user.bio,
  );

  AppUser toDomain(String id) => AppUser(
    id: id,
    name: name,
    email: email,
    role: role,
    createdAt: createdAt,
    bio: bio,
  );
}
