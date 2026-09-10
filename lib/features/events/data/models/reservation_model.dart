enum ReservationStatus { confirmed, pending, waitlist, cancelled }

class ReservationModel {
  final String id;
  final String eventId;
  final String userId;
  final DateTime reservedAt;
  final ReservationStatus status;

  const ReservationModel({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.reservedAt,
    required this.status,
  });

  factory ReservationModel.fromJson(Map<String, dynamic> json) {
    return ReservationModel(
      id: json['id'] as String? ?? '',
      eventId: json['eventId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      reservedAt: DateTime.parse(json['reservedAt'] as String),
      status: ReservationStatus.values.firstWhere(
        (e) => e.name == (json['status'] as String? ?? 'pending'),
        orElse: () => ReservationStatus.pending,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'userId': userId,
      'reservedAt': reservedAt.toIso8601String(),
      'status': status.name,
    };
  }
}
