import 'package:eventhub/features/auth/domain/entities/app_user.dart';

/// Authentication state as seen by the app.
///
/// `ProfileMissing` covers a Firebase account whose Firestore profile does not
/// exist (interrupted sign-up, deleted document). The router sends such users
/// to the profile-completion screen instead of silently logging them out.
sealed class AuthSession {
  const AuthSession();
}

final class SignedOut extends AuthSession {
  const SignedOut();
}

final class SignedIn extends AuthSession {
  const SignedIn(this.user);

  final AppUser user;
}

final class ProfileMissing extends AuthSession {
  const ProfileMissing({required this.uid, required this.email});

  final String uid;
  final String email;
}

extension AuthSessionX on AuthSession {
  AppUser? get userOrNull => switch (this) {
    SignedIn(:final user) => user,
    _ => null,
  };
}
