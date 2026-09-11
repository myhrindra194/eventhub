import 'package:eventhub/features/auth/domain/entities/user_role.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_user.freezed.dart';

/// Authenticated user profile (Firebase Auth uid + Firestore `users/{uid}`).
/// The password never lives in the domain: Firebase Auth owns credentials.
@freezed
abstract class AppUser with _$AppUser {
  const AppUser._();

  const factory AppUser({
    required String id,
    required String name,
    required String email,
    required UserRole role,
    DateTime? createdAt,
  }) = _AppUser;

  bool get isOrganizer => role == UserRole.organizer;
  bool get isParticipant => role == UserRole.participant;
}
