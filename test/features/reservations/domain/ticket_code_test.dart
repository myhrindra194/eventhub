import 'package:eventhub/features/reservations/domain/entities/reservation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String uuid(int n) =>
      '3f2b8c1e-5d4a-4e7b-9c6d-${n.toRadixString(16).padLeft(12, '0')}';

  Reservation withId(String id) => Reservation(
    id: id,
    eventId: 'evt',
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
    final code = withId(uuid(1)).ticketCode;
    expect(
      code,
      matches(RegExp(r'^EH-[2-9A-HJKMNP-Z]{4}-[2-9A-HJKMNP-Z]{4}$')),
    );
  });

  test('is stable for a given reservation id', () {
    expect(withId(uuid(1)).ticketCode, withId(uuid(1)).ticketCode);
    expect(withId(uuid(1)).ticketCode, Reservation.ticketCodeFor(uuid(1)));
  });

  test('differs between reservations', () {
    final codes = {for (var i = 0; i < 200; i++) withId(uuid(i)).ticketCode};
    expect(codes, hasLength(200));
  });

  test('encodes id and code in the QR payload', () {
    final r = withId(uuid(7));
    expect(
      r.ticketPayload,
      'eventhub://ticket/${uuid(7)}?code=${r.ticketCode}',
    );
  });
}
