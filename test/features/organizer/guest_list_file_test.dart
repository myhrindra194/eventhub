import 'dart:convert';

import 'package:eventhub/features/organizer/domain/guest_list_csv.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixtures.dart';

void main() {
  group('GuestListCsv.fileNameFor', () {
    test('folds accents and punctuation into a readable slug', () {
      expect(
        GuestListCsv.fileNameFor('Flutter Meetup — Tanà, édition #3'),
        'participants-flutter-meetup-tana-edition-3.csv',
      );
      expect(
        GuestListCsv.fileNameFor('Cœur & Âme'),
        'participants-coeur-ame.csv',
      );
    });

    test('falls back when the title has nothing usable', () {
      expect(GuestListCsv.fileNameFor(''), 'participants.csv');
      expect(GuestListCsv.fileNameFor('!!! ???'), 'participants.csv');
    });

    test('caps the slug length without a trailing dash', () {
      final name = GuestListCsv.fileNameFor('${'a' * 59} bcdef');
      expect(name, 'participants-${'a' * 59}.csv');
    });
  });

  test('fileBytes starts with a UTF-8 byte-order mark for Excel', () {
    final bytes = GuestListCsv.fileBytes([Fixtures.reservation()]);
    expect(bytes.take(3), [0xEF, 0xBB, 0xBF]);
    expect(utf8.decode(bytes.skip(3).toList()), startsWith('N°;Nom;Email'));
  });
}
