import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class EventImageStorageDataSource {
  static const defaultBucketName = 'eventhub-images';

  final SupabaseClient client;
  final String bucketName;

  EventImageStorageDataSource(
    this.client, {
    this.bucketName = defaultBucketName,
  });

  Future<String> upload({
    required Uint8List bytes,
    required String organizerId,
    required String eventId,
    required String fileExtension,
  }) async {
    final extension = fileExtension.toLowerCase().replaceFirst('.', '');
    final path = 'events/$organizerId/$eventId.$extension';
    final storage = client.storage.from(bucketName);

    try {
      await storage.uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(
          contentType: _contentType(extension),
          upsert: true,
        ),
      );
    } catch (error) {
      final message = error.toString();

      if (message.contains('Bucket not found')) {
        throw StateError(
          'Supabase bucket "$bucketName" not found. '
          'Create it in Supabase Storage or set SUPABASE_EVENT_BUCKET.',
        );
      }

      if (message.contains('403') ||
          message.contains('row level security') ||
          message.contains('Unauthorized')) {
        throw StateError(
          'Supabase Storage upload denied by RLS. '
          'Check the Supabase Storage policies.',
        );
      }

      rethrow;
    }

    return storage.getPublicUrl(path);
  }

  Future<void> delete(String storagePath) async {
    await client.storage.from(bucketName).remove([storagePath]);
  }

  String _contentType(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      default:
        return 'image/jpeg';
    }
  }
}
