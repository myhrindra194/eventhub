import '../../domain/entities/reservation.dart';

class ReservationModel extends Reservation {
  const ReservationModel({
    required super.id,
    required super.eventTitle,
    required super.date,
    required super.status,
    required super.seatInfo,
  });

  factory ReservationModel.fromJson(Map<String, dynamic> json) {
    return ReservationModel(
      id: json['id'] ?? '',
      eventTitle: json['eventTitle'] ?? '',
      date: json['date'] ?? '',
      status: json['status'] ?? 'CONFIRMED',
      seatInfo: json['seatInfo'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventTitle': eventTitle,
      'date': date,
      'status': status,
      'seatInfo': seatInfo,
    };
  }
}
