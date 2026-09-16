import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/auth/domain/entities/app_user.dart';
import 'package:eventhub/features/auth/domain/entities/auth_session.dart';

/// Contrat d’authentification et de persistance du profil.
/// Les implémentations ne doivent jamais lever d’exception ; tout échec est
/// un `Result.err`.
///
/// Un compte, deux espaces (le modèle Eventbrite / Airbnb) : tout compte
/// démarre en participant et active plus tard l’espace organisateur via
/// [becomeOrganizer]. Personne ne choisit de rôle à l’inscription.
abstract interface class AuthRepository {
  /// Émet à chaque changement d’authentification ou de profil (y compris la
  /// vérification de l’e-mail). Ne se termine jamais.
  Stream<AuthSession> watchSession();

  AsyncResult<AppUser> signIn({
    required String email,
    required String password,
  });

  /// Compte Google. Une première connexion n’a pas encore de profil : la
  /// session passe alors en [ProfileMissing] et le router réclame un nom.
  AsyncResult<void> signInWithGoogle();

  /// Crée le compte et son profil participant, connecte l’utilisateur et
  /// envoie l’e-mail de vérification (un échec d’envoi ne fait jamais échouer
  /// l’inscription ; l’utilisateur peut le redemander).
  AsyncResult<AppUser> signUp({
    required String name,
    required String email,
    required String password,
  });

  /// Crée le profil participant d’un compte déjà authentifié (chemin de
  /// rattrapage pour [ProfileMissing], et première connexion Google).
  AsyncResult<AppUser> completeProfile({required String name});

  /// Active l’espace organisateur : e-mail vérifié obligatoire, opération
  /// sans retour. Crée la page publique d’organisateur dans le même batch.
  AsyncResult<AppUser> becomeOrganizer({String bio = ''});

  /// Met à jour les champs de présentation du profil de l’utilisateur
  /// connecté (et de sa page publique d’organisateur).
  ///
  /// Les noms déjà dénormalisés sur les réservations passées ne sont pas
  /// touchés — un billet conserve le nom sous lequel il a été émis.
  /// [bio] reste inchangée lorsqu’elle vaut `null` ; une chaîne vide
  /// l’efface.
  ///
  /// Les photos obéissent à une règle différente, parce qu'un `null` y est
  /// ambigu : il faut [updatePhotos] pour que [photoUrl] et [coverUrl] soient
  /// écrites, et c'est alors `null` qui retire l'image. Sans ce drapeau, un
  /// changement de nom effacerait la photo.
  AsyncResult<AppUser> updateProfile({
    required String name,
    String? bio,
    String? photoUrl,
    String? coverUrl,
    bool updatePhotos = false,
  });

  AsyncResult<void> sendPasswordReset({required String email});

  /// (Re)envoie le lien de vérification à l’adresse de l’utilisateur
  /// connecté.
  AsyncResult<void> sendEmailVerification();

  /// Recharge le compte et, si l’adresse est désormais vérifiée, rafraîchit
  /// l’ID token pour que les règles voient `email_verified == true`
  /// immédiatement. Renvoie le statut de vérification.
  AsyncResult<bool> refreshEmailVerification();

  /// Change le mot de passe du compte actuellement connecté.
  ///
  /// [currentPassword] n’est pas décoratif : le fournisseur exige une
  /// connexion récente pour cette opération, et se réauthentifier avec lui
  /// transforme un « requires-recent-login » sur lequel l’utilisateur ne peut
  /// rien en un banal « mot de passe incorrect » qu’il peut réellement
  /// corriger. C’est aussi la seule chose qui sépare un téléphone
  /// déverrouillé d’un compte volé.
  AsyncResult<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Se déclenche lorsqu’un lien de réinitialisation de mot de passe ouvre
  /// l’application. Firebase termine la réinitialisation sur sa propre page
  /// hébergée, si bien que ce flux reste silencieux ; il est conservé pour
  /// les fournisseurs qui rendent la réinitialisation à l’application.
  Stream<void> get passwordRecoveries;

  /// Définit un nouveau mot de passe sur le compte connecté sans exiger
  /// l’actuel.
  AsyncResult<void> setNewPassword(String newPassword);

  /// Indique si le compte connecté possède un identifiant mot de passe
  /// (sinon c’est un compte Google). Détermine comment [deleteAccount] se
  /// réauthentifie.
  bool get usesPasswordSignIn;

  /// Réauthentifie ([password] pour un compte à mot de passe, Google sinon),
  /// puis supprime le compte : places à venir libérées, historique anonymisé,
  /// données personnelles effacées, utilisateur Authentication supprimé,
  /// déconnexion. Refusé tant qu’un événement à venir du compte a des
  /// participants.
  AsyncResult<void> deleteAccount({String? password});

  AsyncResult<void> signOut();
}
