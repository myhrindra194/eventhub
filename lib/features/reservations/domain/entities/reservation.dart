class Reservation {
  final String id;
  final String eventTitle;
  final String date;
  final String status;
  final String seatInfo;

  const Reservation({
    required this.id,
    required this.eventTitle,
    required this.date,
    required this.status,
    required this.seatInfo,
  });
}
