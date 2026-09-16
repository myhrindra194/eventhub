import 'package:eventhub/features/auth/domain/entities/user_role.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_user.freezed.dart';

/// Profil de l’utilisateur authentifié (uid Firebase Auth + document
/// Firestore `users/{uid}`). Le mot de passe ne vit jamais dans le domaine :
/// c’est Firebase Auth qui détient les identifiants.
@freezed
abstract class AppUser with _$AppUser {
  const AppUser._();

  const factory AppUser({
    required String id,
    required String name,
    required String email,
    required UserRole role,
    DateTime? createdAt,

    /// Organisateurs uniquement : la présentation publiée sur leur profil
    /// public.
    String? bio,

    /// Photo de profil, et bandeau de couverture du profil.
    ///
    /// Chaîne unique pour deux provenances : une URL `https:` ou une image
    /// `data:` embarquée dans le document Firestore. Tout ce qui les affiche
    /// n'a donc qu'un cas à traiter — une URL.
    String? photoUrl,
    String? coverUrl,

    /// Lu depuis Firebase Auth, jamais stocké dans Firestore : c’est au claim
    /// `email_verified` du token que les règles de sécurité se fient.
    @Default(false) bool emailVerified,

    /// Le custom claim `admin`, lu depuis l’ID token — jamais depuis
    /// Firestore, où personne ne pourrait être habilité à l’écrire. Il donne
    /// accès à l’espace de modération ; le serveur revérifie le claim à
    /// chaque appel.
    @Default(false) bool isAdmin,

    /// Le rôle coché dans le formulaire d'inscription, conservé tel quel.
    /// Égal à [role] pour tout compte récent — les deux rôles sont fixés à
    /// l'inscription — ; `null` pour les comptes créés avant la question.
    UserRole? intendedRole,
  }) = _AppUser;

  bool get isOrganizer => role == UserRole.organizer;
  bool get isParticipant => role == UserRole.participant;
}
