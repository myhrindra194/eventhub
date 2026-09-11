import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

/// Uploads event images under `events/{organizerId}/{timestamp}.{ext}`.
class FirebaseStorageDataSource {
  const FirebaseStorageDataSource(this._storage);

  final FirebaseStorage _storage;

  Future<String> uploadEventImage({
    required String organizerId,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final extension = switch (contentType) {
      'image/png' => 'png',
      'image/webp' => 'webp',
      _ => 'jpg',
    };
    final name = '${DateTime.now().millisecondsSinceEpoch}.$extension';
    final ref = _storage.ref('events/$organizerId/$name');
    await ref.putData(bytes, SettableMetadata(contentType: contentType));
    return ref.getDownloadURL();
  }
}
