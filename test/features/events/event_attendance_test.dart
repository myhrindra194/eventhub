import 'package:eventhub/features/events/data/datasources/event_attendance_remote_data_source.dart';
import 'package:eventhub/features/events/domain/entities/event_attendance.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Attendance.sentence', () {
    String? s(int going, [List<String> names = const []]) =>
        Attendance.sentence(going: going, names: names);

    test('says nothing when nobody booked', () {
      expect(s(0), isNull);
      expect(s(0, ['Soa']), isNull);
      expect(s(-1), isNull);
    });

    test('counts people when no name is known yet', () {
      expect(s(1), '1 personne y va');
      expect(s(12), '12 personnes y vont');
    });

    test('names everyone when there are one or two people', () {
      expect(s(1, ['Soa']), 'Soa y va');
      expect(s(2, ['Soa', 'Hery R.']), 'Soa et Hery R. y vont');
    });

    test('names two people and counts the others', () {
      expect(
        s(42, ['Soa', 'Hery R.', 'Fara']),
        'Soa, Hery R. et 40 autres y vont',
      );
      expect(
        s(3, ['Soa', 'Hery R.']),
        'Soa, Hery R. et 1 autre personne y vont',
      );
      expect(s(3, ['Soa']), 'Soa et 2 autres y vont');
    });

    test('never names more people than the head count', () {
      // L'agrégat peut rester un instant en retard sur une annulation.
      expect(s(1, ['Soa', 'Hery R.']), 'Soa y va');
    });

    test('skips blank names', () {
      expect(s(2, ['  ', 'Soa']), 'Soa et 1 autre personne y vont');
    });
  });

  group('EventAttendanceRemoteDataSource.namesFrom', () {
    test('reads names in order and tolerates malformed entries', () {
      expect(
        EventAttendanceRemoteDataSource.namesFrom([
          {'name': 'Soa', 'createdAt': null},
          {'createdAt': null},
          {'name': 42},
          {'name': '   '},
          {'name': ' Hery R. '},
        ]),
        ['Soa', 'Hery R.'],
      );
    });

    test('returns nothing for an empty collection', () {
      expect(EventAttendanceRemoteDataSource.namesFrom(const []), isEmpty);
    });
  });
}
