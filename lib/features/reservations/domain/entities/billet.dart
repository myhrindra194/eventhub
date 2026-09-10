class Billet {
  final String id;
  final String reservationId;
  final String qrCodeData;
  final String seatNumber;

  const Billet({
    required this.id,
    required this.reservationId,
    required this.qrCodeData,
    required this.seatNumber,
  });
}
