class Reservation {
  final String id;
  final String eventId;
  final String eventTitle;
  final String date;
  final String status;
  final String seatInfo;
  final int quantity;

  const Reservation({
    required this.id,
    required this.eventId,
    required this.eventTitle,
    required this.date,
    required this.status,
    required this.seatInfo,
    this.quantity = 1,
  });
}

/// Statut normalisé côté Firestore : 'confirmed' | 'cancelled' | 'past'.
/// Extension pour l'affichage + séparation upcoming/past.
extension ReservationStatusX on Reservation {
  String get displayStatus {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return 'CONFIRMED';
      case 'cancelled':
        return 'CANCELLED';
      case 'past':
        return 'PAST';
      default:
        return status.toUpperCase();
    }
  }

  bool get isPast => status.toLowerCase() == 'past';
}
