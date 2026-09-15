import 'dart:typed_data';

import 'package:eventhub/core/result/result.dart';

/// Binary upload abstraction, implemented over Supabase Storage (public
/// `event-covers` bucket).
abstract interface class ImageStorageRepository {
  /// Uploads [bytes] under the organizer's folder and returns a public URL.
  AsyncResult<String> uploadEventImage({
    required String organizerId,
    required Uint8List bytes,
    required String contentType,
  });
}
