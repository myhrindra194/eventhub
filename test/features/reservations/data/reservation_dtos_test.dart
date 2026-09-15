import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventhub/features/events/domain/entities/event_category.dart';
import 'package:eventhub/features/reservations/data/dtos/booking_event.dart';
import 'package:eventhub/features/reservations/data/dtos/reservation_dto.dart';
import 'package:eventhub/features/reservations/domain/entities/reservation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final startsAt = Timestamp(1790000000, 123456789);

  Map<String, dynamic> eventDoc() => {
    'title': 'Flutter Meetup Antananarivo',
    'description': 'Rencontre.',
    'category': 'meetup',
    'startsAt': startsAt,
    'location': 'Antananarivo',
    'capacity': 4,
    'availablePlaces': 3,
    'organizerId': 'o1',
    'organizerName': 'Mirindra',
    'staffIds': ['o2', 'o1'],
    'currency': 'EUR',
    'tiers': {
      'tvip': {
        'name': 'VIP',
        'description': '',
        'price': 2500,
        'capacity': 2,
        'available': 1,
        'order': 1,
      },
      'tfree': {
        'name': 'Standard',
        'description': '',
        'price': 0,
        'capacity': 2,
        'available': 2,
        'order': 0,
      },
    },
  };

  group('BookingEvent', () {
    test('copies the fields the rules compare, untouched', () {
      final booking = BookingEvent('e1', eventDoc());
      expect(booking.copiedFields, {
        'organizerId': 'o1',
        'eventTitle': 'Flutter Meetup Antananarivo',
        // The very Timestamp, nanoseconds included: a DateTime round trip
        // would make `eventStartsAt == event.startsAt` false.
        'eventStartsAt': same(startsAt),
        'eventLocation': 'Antananarivo',
      });
    });

    test('parses the event the policy needs, tiers in display order', () {
      final event = BookingEvent('e1', eventDoc()).event;
      expect(event.id, 'e1');
      expect(event.category, EventCategory.meetup);
      expect(event.availablePlaces, 3);
      expect(event.tiers.map((t) => t.id), ['tfree', 'tvip']);
      expect(event.tier('tvip')?.isFree, isFalse);
      expect(event.tier('tfree')?.available, 2);
    });

    test('notifies each team member once', () {
      expect(BookingEvent('e1', eventDoc()).teamIds, ['o1', 'o2']);
    });

    test('an event without ticket types has none', () {
      final doc = eventDoc()..remove('tiers');
      expect(BookingEvent('e1', doc).event.hasTiers, isFalse);
    });
  });

  group('ReservationDto', () {
    Map<String, dynamic> reservationDoc() => {
      'eventId': 'e1',
      'userId': 'p1',
      'organizerId': 'o1',
      'userName': 'Soa Rabe',
      'userEmail': 'soa@example.com',
      'eventTitle': 'Flutter Meetup Antananarivo',
      'eventStartsAt': startsAt,
      'eventLocation': 'Antananarivo',
      'status': 'confirmed',
      'reservedAt': Timestamp.fromMillisecondsSinceEpoch(1780000000000),
      'cancelledAt': null,
      'cancelledBy': null,
      'tierId': 'tfree',
      'tierName': 'Standard',
      'pricePaid': 0,
    };

    test('reads a booking written by the transaction', () {
      final r = ReservationDto.fromJson(reservationDoc()).toDomain('e1_p1');
      expect(r.id, 'e1_p1');
      expect(r.isActive, isTrue);
      expect(r.accessLabel, 'Standard');
      expect(r.reservedAt.millisecondsSinceEpoch, 1780000000000);
    });

    test('reads a cancellation and who made it', () {
      final r = ReservationDto.fromJson({
        ...reservationDoc(),
        'status': 'cancelled',
        'cancelledAt': Timestamp.fromMillisecondsSinceEpoch(1780000100000),
        'cancelledBy': 'moderation',
      }).toDomain('e1_p1');
      expect(r.isCancelled, isTrue);
      expect(r.cancelledBy, 'moderation');
    });

    test('an unknown status never reads as a valid seat', () {
      final r = ReservationDto.fromJson({
        ...reservationDoc(),
        'status': 'vip',
      }).toDomain('e1_p1');
      expect(r.status, ReservationStatus.cancelled);
    });
  });
}
