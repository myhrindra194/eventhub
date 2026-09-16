import 'dart:math' as math;

import 'package:eventhub/core/firebase/timestamp_converter.dart';
import 'package:eventhub/features/organizers/domain/organizer_profile.dart';
import 'package:json_annotation/json_annotation.dart';

part 'organizer_profile_dto.g.dart';

/// Document `organizers/{uid}` : la page publique, créée par « Devenir
/// organisateur ». Ses compteurs sont écrits par les clients, mais uniquement
/// à l'intérieur du batch qui les justifie — un abonnement, un événement
/// publié, un avis — ce sont donc les règles qui les gardent honnêtes.
/// L'identifiant du document est injecté par
/// [OrganizerProfileDto.fromFirestore].
@JsonSerializable(createToJson: false)
class OrganizerProfileDto {
  const OrganizerProfileDto({
    required this.id,
    this.name = '',
    this.bio,
    this.photoUrl,
    this.followerCount = 0,
    this.eventCount = 0,
    this.ratingSum = 0,
    this.ratingCount = 0,
    this.memberSince,
  });

  factory OrganizerProfileDto.fromJson(Map<String, dynamic> json) =>
      _$OrganizerProfileDtoFromJson(json);

  factory OrganizerProfileDto.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) => OrganizerProfileDto.fromJson({...data, 'id': id});

  final String id;
  final String name;
  final String? bio;

  /// Recopiée depuis `users/{uid}` dans le même batch, parce que le profil
  /// privé n'est lisible que par son propriétaire : sans ce miroir, personne
  /// ne verrait le visage d'un organisateur sur sa page publique.
  final String? photoUrl;
  final int followerCount;
  final int eventCount;
  final int ratingSum;
  final int ratingCount;

  /// Écrit avec `serverTimestamp()` : `null` dans un snapshot local encore en
  /// attente d'acquittement.
  @NullableTimestampConverter()
  final DateTime? memberSince;

  OrganizerProfile toDomain() => OrganizerProfile(
    id: id,
    name: name,
    bio: bio ?? '',
    photoUrl: photoUrl,
    // Les règles ne déplacent les compteurs que de ±1 ; la borne empêche un
    // document édité à la main d'afficher un jour « -1 abonné ».
    followerCount: math.max(0, followerCount),
    eventCount: math.max(0, eventCount),
    ratingSum: math.max(0, ratingSum),
    ratingCount: math.max(0, ratingCount),
    memberSince: memberSince,
  );
}
