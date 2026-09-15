import 'dart:typed_data';

import 'package:eventhub/core/supabase/db.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Uploads event covers to the public `event-covers` bucket.
///
/// The storage policy accepts an object only under `<auth uid>/<file>`, with
/// a file name of `[A-Za-z0-9._-]`; the bucket itself refuses anything over
/// 5 MB or outside jpeg/png/webp/heic/heif before a policy runs. The public
/// URL is what `events.image_url` stores: covers are promotional by nature,
/// and a replaced cover is removed by the database job queue.
class SupabaseStorageDataSource {
  const SupabaseStorageDataSource(this._client);

  final SupabaseClient _client;

  /// [organizerId] must be the signed-in user: the folder is checked against
  /// `auth.uid()`, not against the argument.
  Future<String> uploadEventImage({
    required String organizerId,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final path = '$organizerId/${fileName(contentType, DateTime.now())}';
    final bucket = _client.storage.from(Buckets.eventCovers);
    await bucket.uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(
        contentType: contentType,
        cacheControl: '31536000',
      ),
    );
    return bucket.getPublicUrl(path);
  }

  /// A new name per upload (`<millis>.<ext>`): public URLs are cached for a
  /// year, so a file is never overwritten in place.
  static String fileName(String contentType, DateTime now) {
    final extension = switch (contentType) {
      'image/png' => 'png',
      'image/webp' => 'webp',
      'image/heic' => 'heic',
      'image/heif' => 'heif',
      _ => 'jpg',
    };
    return '${now.millisecondsSinceEpoch}.$extension';
  }
}
