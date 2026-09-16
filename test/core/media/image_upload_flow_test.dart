import 'dart:io';
import 'dart:typed_data';

import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/errors/failure_exception.dart';
import 'package:eventhub/core/media/device_image_picker.dart';
import 'package:eventhub/core/media/image_kind.dart';
import 'package:eventhub/core/media/image_uploader.dart';
import 'package:eventhub/core/media/media_providers.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';

class _MockImagePicker extends Mock implements ImagePicker {}

class _MockUploader extends Mock implements ImageUploader {}

/// Le sélecteur et le geste « choisir puis envoyer ». Chaque issue — renoncer,
/// image trop lourde, image acceptée — se traduit différemment à l'écran :
/// rien, une phrase, ou un aperçu. Ce fichier les éprouve toutes.
void main() {
  late _MockImagePicker picker;
  late Directory workspace;

  setUpAll(() {
    registerFallbackValue(ImageSource.gallery);
    registerFallbackValue(ImageKind.avatar);
    registerFallbackValue(
      PickedImage(bytes: Uint8List(0), mimeType: 'image/jpeg', filename: 'x'),
    );
  });

  setUp(() {
    picker = _MockImagePicker();
    workspace = Directory.systemTemp.createTempSync('eventhub_image_picker');
  });

  tearDown(() => workspace.deleteSync(recursive: true));

  /// Programme la réponse du greffon : le fichier choisi, ou `null` si
  /// l'utilisateur a refermé la galerie. Le fichier est écrit sur disque,
  /// forme que le greffon rend sur mobile et sur le bureau.
  void whenPicked({int? length, String name = 'photo.jpg', String? mimeType}) {
    XFile? chosen;
    if (length != null) {
      final file = File('${workspace.path}${Platform.pathSeparator}$name')
        ..writeAsBytesSync(Uint8List(length));
      chosen = XFile(file.path, mimeType: mimeType);
    }
    when(
      () => picker.pickImage(
        source: any(named: 'source'),
        maxWidth: any(named: 'maxWidth'),
        maxHeight: any(named: 'maxHeight'),
        imageQuality: any(named: 'imageQuality'),
      ),
    ).thenAnswer((_) async => chosen);
  }

  group('DeviceImagePicker', () {
    test('rend null quand la galerie est refermée sans choix', () async {
      whenPicked();
      final subject = DeviceImagePicker(picker);
      expect(await subject.pick(ImageKind.avatar, PhotoSource.gallery), isNull);
    });

    test('demande la taille propre à chaque usage', () async {
      whenPicked(length: 16);
      await DeviceImagePicker(
        picker,
      ).pick(ImageKind.eventCover, PhotoSource.gallery);
      verify(
        () => picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: ImageKind.eventCover.maxSide,
          maxHeight: ImageKind.eventCover.maxSide,
          imageQuality: any(named: 'imageQuality'),
        ),
      ).called(1);
    });

    test('conserve le type réel du fichier', () async {
      final subject = DeviceImagePicker(picker);
      whenPicked(length: 64, name: 'avatar.bin', mimeType: 'image/png');
      expect(
        (await subject.pick(ImageKind.avatar, PhotoSource.gallery))!.mimeType,
        'image/png',
      );

      whenPicked(length: 64, name: 'avatar.webp');
      expect(
        (await subject.pick(ImageKind.avatar, PhotoSource.camera))!.mimeType,
        'image/webp',
      );
    });

    test('refuse un fichier au-delà du plafond Cloudinary', () async {
      // Sur le bureau et le web, le greffon ne recompresse pas : le fichier
      // est refusé ici, avant une longue attente suivie d'un refus serveur.
      whenPicked(length: DeviceImagePicker.maxBytes + 1);
      await expectLater(
        DeviceImagePicker(picker).pick(ImageKind.avatar, PhotoSource.gallery),
        throwsA(
          isA<FailureException>().having(
            (e) => e.failure.message,
            'message',
            allOf(contains('trop lourde'), contains('Mo')),
          ),
        ),
      );
    });
  });

  group('ImageUploadFlow', () {
    late _MockUploader uploader;

    setUp(() {
      uploader = _MockUploader();
      when(() => uploader.isConfigured).thenReturn(true);
    });

    Future<Result<UploadedImage>?> run() => ImageUploadFlow(
      picker: DeviceImagePicker(picker),
      uploader: uploader,
    ).run(kind: ImageKind.avatar, source: PhotoSource.gallery, ownerId: 'u1');

    test('renoncer n’envoie rien et ne signale rien', () async {
      whenPicked();
      expect(await run(), isNull);
      verifyNever(
        () => uploader.upload(
          any(),
          kind: any(named: 'kind'),
          ownerId: any(named: 'ownerId'),
        ),
      );
    });

    test('un refus local devient une erreur affichable', () async {
      whenPicked(length: DeviceImagePicker.maxBytes + 1);
      expect((await run())!.failureOrNull, isA<ValidationFailure>());
    });

    test('une image acceptée part avec son propriétaire', () async {
      whenPicked(length: 128);
      const uploaded = UploadedImage(
        url: 'https://res.cloudinary.com/demo/image/upload/v1/a.jpg',
        publicId: 'a',
      );
      when(
        () => uploader.upload(
          any(),
          kind: any(named: 'kind'),
          ownerId: any(named: 'ownerId'),
        ),
      ).thenAnswer((_) async => const Ok(uploaded));

      expect(await run(), const Ok(uploaded));
      verify(
        () => uploader.upload(any(), kind: ImageKind.avatar, ownerId: 'u1'),
      ).called(1);
    });
  });
}
