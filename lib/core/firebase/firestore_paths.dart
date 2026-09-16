import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Toutes les collections lues ou écrites par l’app, au même endroit.
///
/// Reflète `firebase/firestore.rules` : une collection renommée devient une
/// erreur de compilation ici, plutôt qu’un `permission-denied` à l’exécution
/// (la règle attrape-tout refuse tout chemin qu’elle ne connaît pas).
abstract final class Collections {
  static const users = 'users';
  static const admins = 'admins';
  static const organizers = 'organizers';
  static const organizerEmails = 'organizerEmails';
  static const events = 'events';
  static const reservations = 'reservations';
  static const reviews = 'reviews';
  static const reports = 'reports';
  static const moderationQueue = 'moderationQueue';

  // users/{uid}/…
  static const private = 'private';
  static const devices = 'devices';
  static const favorites = 'favorites';
  static const following = 'following';
  static const notifications = 'notifications';

  // events/{eventId}/…
  static const waitlist = 'waitlist';
  static const checkins = 'checkins';
  static const invitations = 'invitations';
  static const attendees = 'attendees';

  // moderationQueue/{entryId}/…
  static const decisions = 'decisions';
}

/// Identifiants de documents déterministes. Les règles de sécurité
/// reconstruisent les mêmes ids pour prouver un fait (« cette réservation
/// existe », « un signalement par personne ») : ils sont donc composés ici
/// et nulle part ailleurs.
abstract final class DocIds {
  /// Le document de préférences privées sous `users/{uid}/private`.
  static const notificationPreferences = 'notifications';

  /// Une place par personne et par événement : re-réserver après une
  /// annulation réutilise le même document, donc le même code de billet.
  static String reservation(String eventId, String userId) =>
      '${eventId}_$userId';

  /// Un avis par personne et par événement.
  static String review(String eventId, String userId) => '${eventId}_$userId';

  /// `(eventId, userId)` d’un id de réservation ou d’avis. Les auto-ids
  /// Firestore ne contiennent jamais d’underscore : le dernier sépare donc
  /// la paire.
  static (String eventId, String userId)? splitPair(String id) {
    final cut = id.lastIndexOf('_');
    if (cut <= 0 || cut == id.length - 1) return null;
    return (id.substring(0, cut), id.substring(cut + 1));
  }

  /// Un signalement par personne et par cible.
  static String report(String targetType, String targetId, String reporterId) =>
      '${targetType}_${targetId}_$reporterId';

  static String moderationEntry(String targetType, String targetId) =>
      '${targetType}_$targetId';

  /// Clé de `organizerEmails` : retrouve un co-organisateur à partir de
  /// l’adresse saisie par le propriétaire, sans exposer une liste de comptes.
  static String emailKey(String email) =>
      sha256.convert(utf8.encode(email.trim().toLowerCase())).toString();

  /// Clé de `events/{id}/attendees` : la preuve sociale n’expose jamais un
  /// uid.
  static String attendeeKey(String userId) =>
      sha256.convert(utf8.encode(userId)).toString();
}
