import 'package:eventhub/features/organizer/domain/guest_list_csv.dart';
import 'package:eventhub/features/reservations/domain/entities/reservation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Reservation guest({
    required String userId,
    String name = 'Jean Rakoto',
    String email = 'jean@demo.com',
  }) => Reservation(
    id: 'evt_$userId',
    eventId: 'evt',
    userId: userId,
    organizerId: 'org',
    userName: name,
    userEmail: email,
    eventTitle: 'Flutter Meetup',
    eventStartsAt: DateTime(2026, 10, 24, 18, 30),
    eventLocation: 'Antananarivo',
    status: ReservationStatus.confirmed,
    reservedAt: DateTime(2026, 9, 3, 9, 5),
  );

  test('starts with the header, even for an empty list', () {
    expect(
      GuestListCsv.build(const []),
      'N°;Nom;Email;Réservé le;Billet;Montant payé;Code billet',
    );
  });

  test('numbers rows and uses CRLF line endings', () {
    final g = guest(userId: 'u1');
    final lines = GuestListCsv.build([g, guest(userId: 'u2')]).split('\r\n');

    expect(lines, hasLength(3));
    expect(
      lines[1],
      '1;Jean Rakoto;jean@demo.com;2026-09-03 09:05;Accès général;Gratuit;'
      '${g.ticketCode}',
    );
    expect(lines[2], startsWith('2;'));
  });

  test('prints the ticket type and the amount paid', () {
    final paid = guest(userId: 'u1').copyWith(
      tierId: 'vip',
      tierName: 'VIP',
      pricePaid: 2500,
      currency: 'EUR',
    );
    final line = GuestListCsv.build([paid]).split('\r\n')[1];
    expect(line, contains(';VIP;'));
    expect(line, contains('25,00'));
    expect(line, contains('€'));
  });

  test('quotes values containing the separator or a quote', () {
    final csv = GuestListCsv.build([
      guest(userId: 'u1', name: 'Rakoto; Jean "JR"'),
    ]);
    expect(csv, contains('"Rakoto; Jean ""JR"""'));
  });
}
