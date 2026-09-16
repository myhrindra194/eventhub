import 'package:eventhub/features/events/domain/entities/event_draft.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EventDraft.imageUrlError', () {
    test('a blank cover is allowed: the generated visual stays', () {
      expect(EventDraft.imageUrlError(null), isNull);
      expect(EventDraft.imageUrlError('   '), isNull);
    });

    test('accepts an https link, surrounding spaces included', () {
      expect(
        EventDraft.imageUrlError(
          ' https://images.example.com/cover.jpg?w=1600 ',
        ),
        isNull,
      );
    });

    test('refuses what the rules would refuse', () {
      for (final url in [
        'http://images.example.com/cover.jpg',
        'ftp://images.example.com/cover.jpg',
        'images.example.com/cover.jpg',
        'https://',
        'https://images.example.com/my cover.jpg',
        'https://example.com/${'a' * EventDraft.maxImageUrlLength}',
      ]) {
        expect(EventDraft.imageUrlError(url), isNotNull, reason: url);
      }
    });
  });
}
