import 'user_role.dart';

class User {
  final String id;
  final String email;
  final String name;
  final UserRole role;

  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
  });

  bool get isOrganizer => role == UserRole.organizer;
  bool get isParticipant => role == UserRole.participant;
}
