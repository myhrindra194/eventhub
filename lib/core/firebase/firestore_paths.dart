import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Every collection the app reads or writes, in one place.
///
/// Mirrors `firebase/firestore.rules`: a renamed collection is a compile
/// error here rather than a `permission-denied` at runtime (the catch-all
/// rule refuses any path it does not know).
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

/// Deterministic document ids. The security rules rebuild the same ids to
/// prove a fact ("this booking exists", "one report per person"), so they
/// are composed here and nowhere else.
abstract final class DocIds {
  /// The private preferences document under `users/{uid}/private`.
  static const notificationPreferences = 'notifications';

  /// One seat per person per event: re-booking after a cancellation reuses
  /// the same document, hence the same ticket code.
  static String reservation(String eventId, String userId) =>
      '${eventId}_$userId';

  /// One review per person per event.
  static String review(String eventId, String userId) => '${eventId}_$userId';

  /// `(eventId, userId)` of a reservation or review id. Firestore auto-ids
  /// never contain an underscore, so the last one separates the pair.
  static (String eventId, String userId)? splitPair(String id) {
    final cut = id.lastIndexOf('_');
    if (cut <= 0 || cut == id.length - 1) return null;
    return (id.substring(0, cut), id.substring(cut + 1));
  }

  /// One report per person per target.
  static String report(String targetType, String targetId, String reporterId) =>
      '${targetType}_${targetId}_$reporterId';

  static String moderationEntry(String targetType, String targetId) =>
      '${targetType}_$targetId';

  /// Key of `organizerEmails`: finds a co-organizer by the address the owner
  /// typed without exposing a list of accounts.
  static String emailKey(String email) =>
      sha256.convert(utf8.encode(email.trim().toLowerCase())).toString();

  /// Key of `events/{id}/attendees`: the social proof never shows a uid.
  static String attendeeKey(String userId) =>
      sha256.convert(utf8.encode(userId)).toString();
}
