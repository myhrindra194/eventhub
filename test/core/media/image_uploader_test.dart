import 'dart:convert';
import 'dart:typed_data';

import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/media/device_image_picker.dart';
import 'package:eventhub/core/media/image_kind.dart';
import 'package:eventhub/core/media/image_uploader.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// L'envoi vers Cloudinary est le seul appel réseau de l'app qui ne passe
/// pas par un SDK Firebase : son protocole (multipart, champs, réponses
/// d'erreur) est donc vérifié ici contre un faux client HTTP, sans compte
/// Cloudinary ni réseau.
void main() {
  final image = PickedImage(
    bytes: Uint8List.fromList(List<int>.filled(64, 7)),
    mimeType: 'image/png',
    filename: 'affiche.png',
  );

  CloudinaryImageUploader uploaderWith(
    MockClientStreamHandler handler, {
    String preset = 'eventhub_unsigned',
    Duration timeout = const Duration(seconds: 60),
  }) => CloudinaryImageUploader(
    client: MockClient.streaming(handler),
    cloudName: 'demo',
    uploadPreset: preset,
    timeout: timeout,
  );

  Future<http.StreamedResponse> reply(int status, Object body) async =>
      http.StreamedResponse(
        Stream.value(utf8.encode(jsonEncode(body))),
        status,
      );

  test('envoie un multipart non signé et rend l’URL https', () async {
    late http.MultipartRequest sent;
    final uploader = uploaderWith((request, _) async {
      sent = request as http.MultipartRequest;
      return reply(200, {
        'secure_url':
            'https://res.cloudinary.com/demo/image/upload/v1/eventhub/event-covers/x.png',
        'public_id': 'eventhub/event-covers/x',
        'width': 1600,
        'height': 900,
      });
    });

    final result = await uploader.upload(
      image,
      kind: ImageKind.eventCover,
      ownerId: 'uid-42',
    );

    expect(
      sent.url.toString(),
      'https://api.cloudinary.com/v1_1/demo/image/upload',
    );
    expect(sent.fields, {
      'upload_preset': 'eventhub_unsigned',
      'folder': 'eventhub/event-covers',
      'tags': 'eventhub,eventCover',
      'context': 'uid=uid-42',
    });
    // Aucune clé ni signature ne doit jamais partir de l'appareil.
    expect(sent.fields.keys, isNot(contains('api_key')));
    expect(sent.fields.keys, isNot(contains('signature')));
    expect(sent.files.single.field, 'file');
    expect(sent.files.single.contentType.mimeType, 'image/png');

    final uploaded = (result as Ok<UploadedImage>).value;
    expect(uploaded.url, startsWith('https://res.cloudinary.com/demo/'));
    expect(uploaded.publicId, 'eventhub/event-covers/x');
    expect(uploaded.width, 1600);
  });

  test('sans configuration, refuse sans rien envoyer', () async {
    var called = false;
    final uploader = uploaderWith((_, _) async {
      called = true;
      return reply(200, {});
    }, preset: '');

    expect(uploader.isConfigured, isFalse);
    final result = await uploader.upload(
      image,
      kind: ImageKind.avatar,
      ownerId: 'u',
    );
    expect(result.failureOrNull, isA<StorageFailure>());
    expect(called, isFalse);
  });

  test('traduit les refus de Cloudinary en phrases, sans jargon', () async {
    for (final (status, fragment) in [
      (400, 'JPEG, PNG ou WebP'),
      (401, 'indisponible'),
      (420, 'Trop d’envois'),
      (500, 'échoué'),
    ]) {
      final uploader = uploaderWith(
        (_, _) => reply(status, {
          'error': {'message': 'Upload preset not found'},
        }),
      );
      final failure = (await uploader.upload(
        image,
        kind: ImageKind.avatar,
        ownerId: 'u',
      )).failureOrNull;

      expect(failure, isA<StorageFailure>(), reason: '$status');
      // Le message technique, qui nomme le preset, reste dans les journaux.
      expect(failure!.message, isNot(contains('preset')), reason: '$status');
      expect(failure.message, contains(fragment), reason: '$status');
    }
  });

  test('une coupure réseau devient une NetworkFailure', () async {
    final uploader = uploaderWith(
      (_, _) => throw http.ClientException('Connection reset'),
    );
    final result = await uploader.upload(
      image,
      kind: ImageKind.avatar,
      ownerId: 'u',
    );
    expect(result.failureOrNull, isA<NetworkFailure>());
  });

  test('un envoi trop long est abandonné', () async {
    final uploader = uploaderWith((_, _) async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      return reply(200, {});
    }, timeout: const Duration(milliseconds: 20));
    final result = await uploader.upload(
      image,
      kind: ImageKind.avatar,
      ownerId: 'u',
    );
    expect(result.failureOrNull, isA<NetworkFailure>());
  });
}
