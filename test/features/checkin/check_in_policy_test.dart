import 'package:eventhub/features/checkin/data/check_in_result_dto.dart';
import 'package:eventhub/features/checkin/domain/check_in_policy.dart';
import 'package:eventhub/features/checkin/domain/ticket_payload.dart';
import 'package:eventhub/features/reservations/domain/entities/reservation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const id = '8d7f3a2c-1b4e-4c9a-a5d6-0e2f7b9c4a11';

  Reservation reservation() => Reservation(
    id: id,
    eventId: 'e1',
    userId: 'u1',
    organizerId: 'o1',
    userName: 'Jean Rakoto',
    userEmail: 'jean@example.com',
    eventTitle: 'Flutter Meetup',
    eventStartsAt: DateTime(2030),
    eventLocation: 'Antananarivo',
    status: ReservationStatus.confirmed,
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
      expect(TicketPayload.parse('eventhub://ticket/$id'), isNull);
      expect(TicketPayload.parse('WIFI:S:guest;;'), isNull);
    });

    test('normalises codes typed by hand', () {
      expect(TicketPayload.normalizeCode(' eh-7k2q - m9xd '), 'EH-7K2Q-M9XD');
    });
  });

  group('CheckInPolicy.precheck', () {
    test('leaves a genuine ticket to the server, in any case', () {
      final code = Reservation.ticketCodeFor(id);
      expect(CheckInPolicy.precheck(reservationId: id, code: code), isNull);
      expect(
        CheckInPolicy.precheck(
          reservationId: id.toUpperCase(),
          code: Reservation.ticketCodeFor(id.toUpperCase()).toLowerCase(),
        ),
        isNull,
      );
    });

    test('refuses a code that does not belong to its id', () {
      final verdict = CheckInPolicy.precheck(
        reservationId: id,
        code: 'EH-AAAA-AAAA',
      );
      expect(verdict?.status, CheckInStatus.invalidCode);
      expect(verdict?.isAdmitted, isFalse);
    });

    test('an id that is not a uuid is no reservation', () {
      const legacy = 'e1_u1';
      expect(
        CheckInPolicy.precheck(
          reservationId: legacy,
          code: Reservation.ticketCodeFor(legacy),
        )?.status,
        CheckInStatus.notFound,
      );
    });
  });

  group('CheckInResultDto', () {
    test('maps every status of check_in_ticket', () {
      for (final status in CheckInStatus.values) {
        if (status == CheckInStatus.invalidCode) continue;
        expect(
          CheckInResultDto.fromJson({'status': status.name}).toDomain().status,
          status,
        );
      }
    });

    test('carries the holder and the first scan time', () {
      final verdict = CheckInResultDto.fromJson({
        'status': 'alreadyCheckedIn',
        'reservation_id': id,
        'user_name': 'Jean Rakoto',
        'tier_name': null,
        'price_paid': 0,
        'currency': null,
        'scanned_at': '2030-01-01T18:30:00+00:00',
      }).toDomain();
      expect(verdict.reservationId, id);
      expect(verdict.holderName, 'Jean Rakoto');
      expect(verdict.accessLabel, 'Accès général');
      expect(
        verdict.checkedInAt?.isAtSameMomentAs(DateTime.utc(2030, 1, 1, 18, 30)),
        isTrue,
      );
      expect(verdict.isAdmitted, isFalse);
    });

    test('an unknown status never admits', () {
      expect(
        CheckInResultDto.fromJson({'status': 'vip'}).toDomain().status,
        CheckInStatus.notFound,
      );
    });
  });
}
