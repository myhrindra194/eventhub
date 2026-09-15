import 'package:eventhub/features/reservations/domain/attendee_name.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps the first name and the initial of the next word', () {
    expect(AttendeeName.of('Jean-Marc Rakotomalala'), 'Jean-Marc R.');
    expect(AttendeeName.of('  soa   hery  rabe '), 'soa H.');
    expect(AttendeeName.of('Élodie éva'), 'Élodie É.');
  });

  test('a single word stays as it is', () {
    expect(AttendeeName.of('Soa'), 'Soa');
  });

  test('never exceeds the 40 characters the rules accept', () {
    final name = AttendeeName.of('${'A' * 60} Rabe');
    expect(name.length, AttendeeName.maxLength);
    expect(name, endsWith(' R.'));
  });

  test('a blank name falls back instead of writing nothing', () {
    expect(AttendeeName.of('   '), AttendeeName.fallback);
  });
}
