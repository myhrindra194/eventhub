import 'package:eventhub/features/auth/domain/entities/app_user.dart';

/// État d’authentification tel que l’application le voit.
///
/// `ProfileMissing` couvre un compte Firebase dont le profil Firestore
/// n’existe pas (inscription interrompue, document supprimé). Le router
/// envoie ces utilisateurs vers l’écran de complétion du profil plutôt que de
/// les déconnecter silencieusement.
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
  const ProfileMissing({
    required this.uid,
    required this.email,
    this.displayName,
  });

  final String uid;
  final String email;

  /// Fourni par Google Sign-In ; pré-remplit le formulaire de complétion du
  /// profil.
  final String? displayName;
}

extension AuthSessionX on AuthSession {
  AppUser? get userOrNull => switch (this) {
    SignedIn(:final user) => user,
    _ => null,
  };
}
