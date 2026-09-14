/// Firestore collection names and field keys. Keep in sync with
/// `firebase/firestore.rules` and `firebase/firestore.indexes.json`.
abstract final class FirestorePaths {
  static const users = 'users';
  static const events = 'events';
  static const reservations = 'reservations';

  // users/{uid} subcollections
  static const devices = 'devices';
  static const private = 'private';
  static const notifications = 'notifications';
  static const favorites = 'favorites';
  static const following = 'following';

  // events/{id} subcollections
  static const waitlist = 'waitlist';
  static const checkins = 'checkins';

  static const reviews = 'reviews';
  static const reports = 'reports';

  /// organizers/{uid} — public organizer profile, written by functions only.
  static const organizers = 'organizers';

  /// moderationQueue/{targetType}_{targetId} and admins/{uid} — admin-only.
  static const moderationQueue = 'moderationQueue';
  static const admins = 'admins';

  /// aggregates/{docId} — server-maintained, read-only for clients.
  static const aggregates = 'aggregates';

  /// aggregates/event_{eventId} — recent attendees of an event (F-07).
  static String eventAggregateDoc(String eventId) => 'event_$eventId';

  /// users/{uid}/private/notifications — push preferences. Same document
  /// path is read by the Cloud Functions before sending.
  static const notificationPreferencesDoc = 'notifications';
}

abstract final class EventFields {
  static const title = 'title';
  static const description = 'description';
  static const imageUrl = 'imageUrl';
  static const category = 'category';
  static const startsAt = 'startsAt';
  static const location = 'location';
  static const capacity = 'capacity';
  static const availablePlaces = 'availablePlaces';
  static const organizerId = 'organizerId';
  static const organizerName = 'organizerName';
  static const createdAt = 'createdAt';
  static const updatedAt = 'updatedAt';
}

abstract final class ReservationFields {
  static const eventId = 'eventId';
  static const userId = 'userId';
  static const organizerId = 'organizerId';
  static const status = 'status';
  static const reservedAt = 'reservedAt';
  static const cancelledAt = 'cancelledAt';
}

abstract final class UserFields {
  static const name = 'name';
  static const email = 'email';
  static const role = 'role';
  static const bio = 'bio';
  static const createdAt = 'createdAt';
  static const updatedAt = 'updatedAt';
}
