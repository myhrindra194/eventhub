import '../../domain/entities/reservation.dart';

class ReservationModel {
  final String id;
  final String eventTitle;
  final String date;
  final String status;
  final String seatInfo;

  const ReservationModel({
    required this.id,
    required this.eventTitle,
    required this.date,
    required this.status,
    required this.seatInfo,
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

  Reservation toEntity() {
    return Reservation(
      id: id,
      eventTitle: eventTitle,
      date: date,
      status: status,
      seatInfo: seatInfo,
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
