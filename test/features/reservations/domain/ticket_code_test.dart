import 'package:eventhub/features/reservations/domain/entities/reservation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Reservation withId(String eventId, String userId) => Reservation(
    id: Reservation.composeId(eventId: eventId, userId: userId),
    eventId: eventId,
    userId: userId,
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
    final code = withId('flutter-meetup-mg', 'user-jean').ticketCode;
    expect(
      code,
      matches(RegExp(r'^EH-[2-9A-HJKMNP-Z]{4}-[2-9A-HJKMNP-Z]{4}$')),
    );
  });

  test('is stable for a given reservation', () {
    expect(withId('evt', 'u1').ticketCode, withId('evt', 'u1').ticketCode);
  });

  test('differs between reservations', () {
    final codes = {
      for (var i = 0; i < 200; i++) withId('evt', 'user-$i').ticketCode,
    };
    expect(codes, hasLength(200));
  });

  test('encodes id and code in the QR payload', () {
    final r = withId('evt', 'u1');
    expect(r.ticketPayload, 'eventhub://ticket/evt_u1?code=${r.ticketCode}');
  });
}
