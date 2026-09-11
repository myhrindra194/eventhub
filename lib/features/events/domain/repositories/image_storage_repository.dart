import 'dart:typed_data';

import 'package:eventhub/core/result/result.dart';

/// Binary upload abstraction. The current implementation targets Firebase
/// Storage; swapping to Supabase Storage only requires a new data source.
abstract interface class ImageStorageRepository {
  /// Uploads [bytes] under the organizer's folder and returns a public URL.
  AsyncResult<String> uploadEventImage({
    required String organizerId,
    required Uint8List bytes,
    required String contentType,
  });
}
