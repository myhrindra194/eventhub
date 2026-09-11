import 'dart:typed_data';

import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/events/data/datasources/firebase_storage_data_source.dart';
import 'package:eventhub/features/events/domain/repositories/image_storage_repository.dart';

class ImageStorageRepositoryImpl implements ImageStorageRepository {
  const ImageStorageRepositoryImpl(this._storage);

  final FirebaseStorageDataSource _storage;

  @override
  AsyncResult<String> uploadEventImage({
    required String organizerId,
    required Uint8List bytes,
    required String contentType,
  }) {
    return guard(
      () => _storage.uploadEventImage(
        organizerId: organizerId,
        bytes: bytes,
        contentType: contentType,
      ),
    );
  }
}
