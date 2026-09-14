import 'package:eventhub/features/checkin/domain/check_in_policy.dart';
import 'package:eventhub/features/checkin/domain/ticket_payload.dart';
import 'package:eventhub/features/reservations/domain/entities/reservation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Reservation reservation({
    String eventId = 'e1',
    ReservationStatus status = ReservationStatus.confirmed,
  }) => Reservation(
    id: Reservation.composeId(eventId: eventId, userId: 'u1'),
    eventId: eventId,
    userId: 'u1',
    organizerId: 'o1',
    userName: 'Jean Rakoto',
    userEmail: 'jean@example.com',
    eventTitle: 'Flutter Meetup',
    eventStartsAt: DateTime(2030),
    eventLocation: 'Antananarivo',
    status: status,
    reservedAt: DateTime(2029),
  );

  group('TicketPayload.parse', () {
    test('round-trips the payload encoded in the ticket QR', () {
      final r = reservation();
      final payload = TicketPayload.parse(r.ticketPayload);
      expect(payload?.reservationId, r.id);
      expect(payload?.code, r.ticketCode);
    });

    test('rejects anything that is not an EventHub ticket', () {
      expect(TicketPayload.parse('https://eventhub.app/e/e1'), isNull);
      expect(TicketPayload.parse('eventhub://ticket/?code=EH-1'), isNull);
      expect(TicketPayload.parse('eventhub://ticket/e1_u1'), isNull);
      expect(TicketPayload.parse('WIFI:S:guest;;'), isNull);
    });

    test('normalises codes typed by hand', () {
      expect(TicketPayload.normalizeCode(' eh-7k2q - m9xd '), 'EH-7K2Q-M9XD');
    });
  });

  group('CheckInPolicy.evaluate', () {
    CheckInStatus status({
      Reservation? r,
      String eventId = 'e1',
      String? code,
      DateTime? checkedInAt,
    }) => CheckInPolicy.evaluate(
      eventId: eventId,
      code: code ?? r?.ticketCode ?? 'EH-XXXX-XXXX',
      reservation: r,
      checkedInAt: checkedInAt,
    ).status;

    test('admits a valid, unused ticket', () {
      expect(status(r: reservation()), CheckInStatus.admitted);
    });

    test('accepts the code in any case', () {
      final r = reservation();
      expect(
        status(r: r, code: r.ticketCode.toLowerCase()),
        CheckInStatus.admitted,
      );
    });

    test('refuses, most severe first', () {
      expect(status(), CheckInStatus.notFound);
      expect(status(r: reservation(eventId: 'e2')), CheckInStatus.wrongEvent);
      expect(
        status(r: reservation(), code: 'EH-AAAA-AAAA'),
        CheckInStatus.invalidCode,
      );
      expect(
        status(r: reservation(status: ReservationStatus.pending)),
        CheckInStatus.unpaid,
      );
      expect(
        status(r: reservation(status: ReservationStatus.cancelled)),
        CheckInStatus.cancelled,
      );
      expect(
        status(r: reservation(), checkedInAt: DateTime(2030)),
        CheckInStatus.alreadyCheckedIn,
      );
    });
  });
}
