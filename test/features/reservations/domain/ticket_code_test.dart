import 'package:eventhub/features/reservations/domain/entities/reservation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// `<eventId>_<uid>`, shaped like Firestore auto ids and Firebase uids.
  String idFor(int n) => 'Xk3Pq9LmZr2Tb7Wc4Yd1_${'u$n'.padLeft(28, 'A')}';

  Reservation withId(String id) => Reservation(
    id: id,
    eventId: 'Xk3Pq9LmZr2Tb7Wc4Yd1',
    userId: 'u1',
    organizerId: 'org',
    userName: 'Jean Rakoto',
    userEmail: 'jean@demo.com',
    eventTitle: 'Flutter Meetup',
    eventStartsAt: DateTime(2026, 10, 24),
    eventLocation: 'Antananarivo',
    status: ReservationStatus.confirmed,
    reservedAt: DateTime(2026, 9, 3),
  );

  test('has the EH-XXXX-XXXX shape without ambiguous characters', () {
    final code = withId(idFor(1)).ticketCode;
    expect(
      code,
      matches(RegExp(r'^EH-[2-9A-HJKMNP-Z]{4}-[2-9A-HJKMNP-Z]{4}$')),
    );
  });

  test('is stable for a given reservation id', () {
    expect(withId(idFor(1)).ticketCode, withId(idFor(1)).ticketCode);
    expect(withId(idFor(1)).ticketCode, Reservation.ticketCodeFor(idFor(1)));
  });

  test('differs between reservations of one event', () {
    final codes = {for (var i = 0; i < 200; i++) withId(idFor(i)).ticketCode};
    expect(codes, hasLength(200));
  });

  test('encodes id and code in the QR payload', () {
    final r = withId(idFor(7));
    expect(
      r.ticketPayload,
      'eventhub://ticket/${idFor(7)}?code=${r.ticketCode}',
    );
  });
}
