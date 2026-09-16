import 'package:eventhub/core/firebase/timestamp_converter.dart';
import 'package:eventhub/features/team/domain/team.dart';
import 'package:json_annotation/json_annotation.dart';

part 'staff_invitation_dto.g.dart';

/// Document `events/{eventId}/invitations/{inviteeId}`.
///
/// Il porte une copie de ce dont l’invité a besoin pour décider — titre et
/// date de l’événement, nom de celui qui invite — parce que l’invité ne peut
/// pas lire le profil de l’invitant, et ne peut lire l’événement qu’une fois
/// dans l’équipe.
@JsonSerializable(createToJson: false)
class StaffInvitationDto {
  const StaffInvitationDto({
    this.eventId = '',
    this.userId = '',
    this.email = '',
    this.name = '',
    this.invitedByName = '',
    this.eventTitle = '',
    this.eventStartsAt,
    this.status,
    this.createdAt,
  });

  factory StaffInvitationDto.fromJson(Map<String, dynamic> json) =>
      _$StaffInvitationDtoFromJson(json);

  final String eventId;
  final String userId;
  final String email;
  final String name;
  final String invitedByName;
  final String eventTitle;

  @NullableTimestampConverter()
  final DateTime? eventStartsAt;

  /// Conservé en texte : une valeur inconnue se lit comme « en attente »
  /// plutôt que de faire échouer toute la liste.
  final String? status;

  /// Heure serveur : `null` dans l’instantané local en attente de l’invitant.
  @NullableTimestampConverter()
  final DateTime? createdAt;

  StaffInvitation toDomain() => StaffInvitation(
    eventId: eventId,
    userId: userId,
    email: email,
    name: name,
    invitedByName: invitedByName,
    eventTitle: eventTitle,
    eventStartsAt: eventStartsAt,
    status: InvitationStatus.fromWire(status),
    createdAt: createdAt,
  );
}
