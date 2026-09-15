import 'package:eventhub/core/supabase/timestamp_converter.dart';
import 'package:eventhub/features/team/domain/team.dart';
import 'package:json_annotation/json_annotation.dart';

part 'staff_invitation_dto.g.dart';

/// Row of `public.staff_invitations`, written only by the team RPCs. It
/// carries a copy of what the invitee needs to decide (event title, date,
/// inviter's name) because the invitee cannot read the inviter's profile.
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
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

  /// Kept as text: an unknown value reads as pending rather than failing
  /// the whole list.
  final String? status;
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
