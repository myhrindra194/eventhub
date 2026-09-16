import 'dart:io';
import 'dart:typed_data';

import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/errors/failure_exception.dart';
import 'package:eventhub/core/utils/image_data_url.dart';
import 'package:eventhub/features/auth/data/datasources/profile_photo_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';

class _MockImagePicker extends Mock implements ImagePicker {}

/// Sans Cloud Storage, l'image choisie entre dans le document Firestore : sa
/// taille cesse d'être un détail de confort pour devenir une contrainte que
/// les règles font respecter. Ce fichier éprouve les trois issues du
/// sélecteur — l'utilisateur renonce, l'image est trop lourde, l'image passe —
/// parce que chacune se traduit très différemment à l'écran.
void main() {
  late _MockImagePicker picker;
  late ProfilePhotoPicker subject;
  late Directory workspace;

  setUpAll(() => registerFallbackValue(ImageSource.gallery));

  setUp(() {
    picker = _MockImagePicker();
    subject = ProfilePhotoPicker(picker);
    workspace = Directory.systemTemp.createTempSync('eventhub_photo_picker');
  });

  tearDown(() => workspace.deleteSync(recursive: true));

  /// Programme la réponse du greffon : le fichier que l'utilisateur a choisi,
  /// ou `null` s'il a refermé la galerie.
  ///
  /// Le fichier est écrit sur disque plutôt que construit en mémoire, parce
  /// que c'est la forme que le greffon rend sur mobile et sur le bureau : un
  /// chemin, dont l'extension porte le type quand aucun n'est déclaré.
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

  test('rend null quand la galerie est refermée sans choix', () async {
    whenPicked();
    expect(await subject.pickAvatar(PhotoSource.gallery), isNull);
  });

  test('encode l’image choisie en URL data:', () async {
    whenPicked(length: 2048, mimeType: 'image/jpeg');

    final encoded = await subject.pickAvatar(PhotoSource.gallery);

    expect(ImageDataUrl.isDataUrl(encoded), isTrue);
    expect(ImageDataUrl.decode(encoded!), hasLength(2048));
  });

  test('conserve le type réel du fichier, jamais un défaut', () async {
    // Annoncer du JPEG pour un PNG donnerait une image illisible à
    // l'affichage : le type suit le contenu, déclaré par le greffon sur le
    // web, déduit de l'extension du chemin partout ailleurs.
    whenPicked(length: 64, name: 'avatar.bin', mimeType: 'image/png');
    expect(
      await subject.pickAvatar(PhotoSource.gallery),
      startsWith('data:image/png;base64,'),
    );

    whenPicked(length: 64, name: 'avatar.webp');
    expect(
      await subject.pickAvatar(PhotoSource.camera),
      startsWith('data:image/webp;base64,'),
    );
  });

  test('refuse une image au-delà du plafond, avec une phrase utile', () async {
    whenPicked(length: ImageDataUrl.maxAvatarBytes + 1);

    // Sur le bureau et le web, le greffon ignore `imageQuality` : une image
    // non recompressée peut donc dépasser le budget. Elle est refusée ici,
    // et non silencieusement tronquée ni envoyée pour être rejetée par les
    // règles avec un `permission-denied` incompréhensible.
    await expectLater(
      subject.pickAvatar(PhotoSource.gallery),
      throwsA(
        isA<FailureException>().having(
          (e) => e.failure,
          'failure',
          isA<ValidationFailure>().having(
            (f) => f.message,
            'message',
            allOf(contains('trop lourde'), contains('Ko')),
          ),
        ),
      ),
    );
  });

  test('la couverture dispose d’un budget plus large que l’avatar', () async {
    // Une bande de couverture est plus large qu'une photo de visage : ce qui
    // est refusé pour l'une doit passer pour l'autre.
    const between = ImageDataUrl.maxAvatarBytes + 1024;
    expect(between, lessThan(ImageDataUrl.maxCoverBytes));

    whenPicked(length: between);
    expect(await subject.pickCover(PhotoSource.gallery), isNotNull);

    whenPicked(length: ImageDataUrl.maxCoverBytes + 1);
    await expectLater(
      subject.pickCover(PhotoSource.gallery),
      throwsA(isA<FailureException>()),
    );
  });
}
