import 'package:eventhub/features/events/data/datasources/supabase_storage_data_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SupabaseStorageDataSource.fileName', () {
    final now = DateTime.utc(2026, 9, 15, 12);

    test('matches the storage policy and the bucket types', () {
      final policy = RegExp(r'^[A-Za-z0-9._-]{1,128}$');
      for (final type in [
        'image/jpeg',
        'image/png',
        'image/webp',
        'image/heic',
        'image/heif',
      ]) {
        final name = SupabaseStorageDataSource.fileName(type, now);
        expect(policy.hasMatch(name), isTrue, reason: name);
        expect(name.contains('..'), isFalse);
      }
    });

    test('derives the extension from the content type', () {
      String ext(String type) =>
          SupabaseStorageDataSource.fileName(type, now).split('.').last;
      expect(ext('image/png'), 'png');
      expect(ext('image/webp'), 'webp');
      expect(ext('image/heic'), 'heic');
      expect(ext('image/jpeg'), 'jpg');
    });
  });
}
