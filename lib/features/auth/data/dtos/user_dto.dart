import 'package:eventhub/core/firebase/timestamp_converter.dart';
import 'package:eventhub/features/auth/domain/entities/app_user.dart';
import 'package:eventhub/features/auth/domain/entities/user_role.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_dto.freezed.dart';
part 'user_dto.g.dart';

/// Document `users/{uid}`. The id is read separately by the repository.
@freezed
abstract class UserDto with _$UserDto {
  const UserDto._();

  const factory UserDto({
    required String name,
    required String email,
    @JsonKey(unknownEnumValue: UserRole.participant) required UserRole role,

    /// `null` in the pending local snapshot of a fresh sign-up.
    @NullableTimestampConverter() DateTime? createdAt,

    String? bio,

    /// Set by moderation: the account reads but can no longer write.
    @Default(false) bool suspended,

    /// Stamped when the welcome notification was written.
    @NullableTimestampConverter() DateTime? welcomedAt,
  }) = _UserDto;

  factory UserDto.fromJson(Map<String, dynamic> json) =>
      _$UserDtoFromJson(json);

  AppUser toDomain(String id) => AppUser(
    id: id,
    name: name,
    email: email,
    role: role,
    createdAt: createdAt,
    bio: bio,
  );
}
