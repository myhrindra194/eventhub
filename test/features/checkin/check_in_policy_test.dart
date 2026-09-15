import 'package:eventhub/features/checkin/domain/check_in_policy.dart';
import 'package:eventhub/features/checkin/domain/ticket_payload.dart';
import 'package:eventhub/features/reservations/domain/entities/reservation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const eventId = 'Xk3Pq9LmZr2Tb7Wc4Yd1';
  const userId = 'aB3dE5fG7hJ9kL1mN3pQ5rS7tU9';
  const id = '${eventId}_$userId';
  final now = DateTime(2030, 1, 1, 18, 30);

  Reservation reservation({
    ReservationStatus status = ReservationStatus.confirmed,
    String event = eventId,
    String? tierName,
  }) => Reservation(
    id: id,
    eventId: event,
    userId: userId,
    organizerId: 'o1',
    userName: 'Jean Rakoto',
    userEmail: 'jean@example.com',
    eventTitle: 'Flutter Meetup',
    eventStartsAt: DateTime(2030),
    eventLocation: 'Antananarivo',
    status: status,
    reservedAt: DateTime(2029),
    tierName: tierName,
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
      expect(TicketPayload.parse('eventhub://ticket/$id'), isNull);
      expect(TicketPayload.parse('WIFI:S:guest;;'), isNull);
    });

    test('normalises codes typed by hand', () {
      expect(TicketPayload.normalizeCode(' eh-7k2q - m9xd '), 'EH-7K2Q-M9XD');
    });
  });

  group('CheckInPolicy.precheck', () {
    CheckInVerdict? precheck(String reservationId, String code) =>
        CheckInPolicy.precheck(
          eventId: eventId,
          reservationId: reservationId,
          code: code,
        );

    test('leaves a genuine ticket of this event to the server', () {
      final code = Reservation.ticketCodeFor(id);
      expect(precheck(id, code), isNull);
      expect(precheck(id, code.toLowerCase()), isNull);
    });

    test('refuses a code that does not belong to its id', () {
      final verdict = precheck(id, 'EH-AAAA-AAAA');
      expect(verdict?.status, CheckInStatus.invalidCode);
      expect(verdict?.isAdmitted, isFalse);
    });

    test('a ticket of another event is refused before any read', () {
      const other = 'Zz9Yy8Xx7Ww6Vv5Uu4Tt3_$userId';
      final verdict = precheck(other, Reservation.ticketCodeFor(other));
      expect(verdict?.status, CheckInStatus.wrongEvent);
      expect(verdict?.holderName, isNull);
    });

    test('an id that is not <eventId>_<uid> is no reservation', () {
      for (final bad in [
        '8d7f3a2c-1b4e-4c9a-a5d6-0e2f7b9c4a11',
        'e1-u1',
        '_$userId',
        '${eventId}_',
        '$eventId/x_$userId',
      ]) {
        expect(
          precheck(bad, Reservation.ticketCodeFor(bad))?.status,
          CheckInStatus.notFound,
          reason: bad,
        );
      }
    });
  });

  group('CheckInPolicy.judge', () {
    CheckInVerdict judge(
      Reservation? r, {
      bool alreadyScanned = false,
      DateTime? scannedAt,
    }) => CheckInPolicy.judge(
      eventId: eventId,
      reservationId: id,
      reservation: r,
      alreadyScanned: alreadyScanned,
      scannedAt: scannedAt,
      now: now,
    );

    test('admits a confirmed, unused ticket, with its holder', () {
      final verdict = judge(reservation(tierName: 'VIP'));
      expect(verdict.isAdmitted, isTrue);
      expect(verdict.holderName, 'Jean Rakoto');
      expect(verdict.accessLabel, 'VIP');
      expect(verdict.checkedInAt, now);
    });

    test('a second scan says when the ticket was first used', () {
      final first = DateTime(2030, 1, 1, 18, 2);
      final verdict = judge(
        reservation(),
        alreadyScanned: true,
        scannedAt: first,
      );
      expect(verdict.status, CheckInStatus.alreadyCheckedIn);
      expect(verdict.checkedInAt, first);
      expect(verdict.accessLabel, 'Accès général');
    });

    test('refuses a cancelled seat, even one scanned before', () {
      expect(
        judge(
          reservation(status: ReservationStatus.cancelled),
          alreadyScanned: true,
        ).status,
        CheckInStatus.cancelled,
      );
    });

    test('refuses an unknown ticket and another event\'s, without a name', () {
      expect(judge(null).status, CheckInStatus.notFound);
      final wrong = judge(reservation(event: 'other'));
      expect(wrong.status, CheckInStatus.wrongEvent);
      expect(wrong.holderName, isNull);
    });
  });
}
