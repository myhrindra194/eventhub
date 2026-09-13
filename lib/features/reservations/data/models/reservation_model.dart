import '../../domain/entities/reservation.dart';

class ReservationModel {
  final String id;
  final String eventId;
  final String eventTitle;
  final String date;
  final String status;
  final String seatInfo;
  final int quantity;

  const ReservationModel({
    required this.id,
    required this.eventId,
    required this.eventTitle,
    required this.date,
    required this.status,
    required this.seatInfo,
    this.quantity = 1,
  });

  factory ReservationModel.fromJson(Map<String, dynamic> json) {
    int asInt(Object? value) =>
        value is num ? value.toInt() : int.tryParse('$value') ?? 1;
    String asStatus(Object? value) {
      final normalized = (value ?? 'confirmed').toString().toLowerCase();
      return normalized.isEmpty ? 'confirmed' : normalized;
    }

    return ReservationModel(
      id: (json['id'] ?? '').toString(),
      eventId: (json['eventId'] ?? '').toString(),
      eventTitle: (json['eventTitle'] ?? '').toString(),
      date: (json['date'] ?? '').toString(),
      status: asStatus(json['status']),
      seatInfo: (json['seatInfo'] ?? '').toString(),
      quantity: asInt(json['quantity']),
    );
  }

  Reservation toEntity() {
    return Reservation(
      id: id,
      eventId: eventId,
      eventTitle: eventTitle,
      date: date,
      status: status,
      seatInfo: seatInfo,
      quantity: quantity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'eventTitle': eventTitle,
      'date': date,
      'status': status,
      'seatInfo': seatInfo,
      'quantity': quantity,
    };
  }
}
