/// Firestore collection names and field keys. Keep in sync with
/// `firebase/firestore.rules` and `firebase/firestore.indexes.json`.
abstract final class FirestorePaths {
  static const users = 'users';
  static const events = 'events';
  static const reservations = 'reservations';
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
  static const createdAt = 'createdAt';
}
