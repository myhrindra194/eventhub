import 'package:eventhub/core/utils/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String plain(String s) => s.replaceAll(RegExp(r'\s'), ' ');

  group('Money.format', () {
    test('prints cents with a decimal comma and the symbol', () {
      expect(plain(Money.format(2500, 'EUR')), '25,00 €');
      expect(plain(Money.format(1250, 'usd')), r'12,50 $');
    });

    test('prints ariary without decimals, grouped by thousands', () {
      expect(plain(Money.format(15000, 'MGA')), '15 000 Ar');
    });
  });

  group('Money.parse', () {
    test('reads what an organizer types', () {
      expect(Money.parse('12,5', 'EUR'), 1250);
      expect(Money.parse('12.50', 'EUR'), 1250);
      expect(Money.parse(' 15 000 ', 'MGA'), 15000);
      expect(Money.parse('', 'EUR'), 0);
    });

    test('refuses what is not a non-negative amount', () {
      expect(Money.parse('abc', 'EUR'), isNull);
      expect(Money.parse('-3', 'EUR'), isNull);
    });

    test('round-trips through inputValue', () {
      expect(Money.parse(Money.inputValue(1999, 'EUR'), 'EUR'), 1999);
      expect(Money.parse(Money.inputValue(20000, 'MGA'), 'MGA'), 20000);
    });
  });
}
