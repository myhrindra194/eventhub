import 'package:eventhub/core/firebase/timestamp_converter.dart';
import 'package:eventhub/features/auth/domain/entities/app_user.dart';
import 'package:eventhub/features/auth/domain/entities/user_role.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_dto.freezed.dart';
part 'user_dto.g.dart';

/// Document `users/{uid}`. L’id est lu séparément par le repository.
@freezed
abstract class UserDto with _$UserDto {
  const UserDto._();

  const factory UserDto({
    required String name,
    required String email,
    @JsonKey(unknownEnumValue: UserRole.participant) required UserRole role,

    /// `null` dans le snapshot local en attente d’une inscription toute
    /// fraîche.
    @NullableTimestampConverter() DateTime? createdAt,

    String? bio,

    /// Photo de profil et photo de couverture.
    ///
    /// Une URL `https:`, ou une image encodée dans le document lui-même
    /// (`data:`) : sans Cloud Storage sur le plan Spark, c'est Firestore qui
    /// porte l'image. Voir `ImageDataUrl` pour les bornes de taille.
    String? photoUrl,
    String? coverUrl,

    /// Posé par la modération : le compte lit mais ne peut plus écrire.
    @Default(false) bool suspended,

    /// Horodaté au moment où la notification de bienvenue a été écrite.
    @NullableTimestampConverter() DateTime? welcomedAt,

    /// Rôle choisi à l'inscription ; voir [AppUser.intendedRole].
    @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
    UserRole? intendedRole,
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
    photoUrl: photoUrl,
    coverUrl: coverUrl,
    intendedRole: intendedRole,
  );
}
