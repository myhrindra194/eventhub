import 'dart:convert';
import 'dart:typed_data';

import 'package:eventhub/core/utils/image_data_url.dart';
import 'package:flutter_test/flutter_test.dart';

/// Les images de profil voyagent dans le document Firestore lui-même, faute
/// de Cloud Storage sur le plan Spark. Deux choses doivent donc tenir, et ce
/// sont les seules que ce fichier vérifie :
///
///  1. l'encodage est réversible et tolérant — une chaîne abîmée dégrade vers
///     le repli visuel, elle ne fait pas tomber l'écran qui l'affiche ;
///  2. le budget du client reste **sous le plafond inscrit dans les règles**,
///     lui-même très en dessous de la limite d'un document Firestore. C'est
///     le test le plus utile du fichier : il relie deux constantes qui vivent
///     dans deux langages différents et que rien d'autre ne tient ensemble.
void main() {
  Uint8List bytes(int length) =>
      Uint8List.fromList(List<int>.generate(length, (i) => i % 256));

  group('encodage', () {
    test('produit une URL data: réversible', () {
      final source = bytes(512);
      final url = ImageDataUrl.encode(source);

      expect(url, startsWith('data:image/jpeg;base64,'));
      expect(ImageDataUrl.isDataUrl(url), isTrue);
      expect(ImageDataUrl.decode(url), equals(source));
    });

    test('porte le type réel de l’image', () {
      final url = ImageDataUrl.encode(bytes(16), mimeType: 'image/png');
      expect(url, startsWith('data:image/png;base64,'));
      // Annoncer du JPEG pour un PNG donnerait une image illisible : le type
      // doit suivre le contenu, pas une valeur par défaut.
      expect(url, isNot(contains('jpeg')));
    });
  });

  group('reconnaissance', () {
    test('ne confond pas une URL distante avec une image embarquée', () {
      expect(ImageDataUrl.isDataUrl('https://example.com/a.jpg'), isFalse);
      expect(ImageDataUrl.isDataUrl(''), isFalse);
      expect(ImageDataUrl.isDataUrl(null), isFalse);
    });
  });

  group('décodage tolérant', () {
    test('rend null plutôt que de lever sur une chaîne inutilisable', () {
      // Aucun de ces cas ne doit faire tomber l'écran : l'appelant pose son
      // repli (initiales, dégradé déterministe) quand il reçoit null.
      expect(ImageDataUrl.decode('https://example.com/a.jpg'), isNull);
      expect(ImageDataUrl.decode('data:image/jpeg;base64'), isNull);
      expect(ImageDataUrl.decode('data:image/jpeg;base64,???'), isNull);
    });

    test('accepte une charge utile vide sans erreur', () {
      expect(ImageDataUrl.decode('data:image/png;base64,'), isEmpty);
    });
  });

  group('budget de taille', () {
    test('la longueur annoncée majore la longueur réelle', () {
      for (final raw in [1, 100, 4096, ImageDataUrl.maxAvatarBytes]) {
        expect(
          ImageDataUrl.encode(bytes(raw)).length,
          lessThanOrEqualTo(ImageDataUrl.maxEncodedLength(raw)),
          reason: '$raw octets',
        );
      }
    });

    test('reste sous les plafonds de firestore.rules', () {
      // `validImageRef` borne photoUrl à 140 000 et coverUrl à 280 000
      // caractères. Si quelqu'un augmente un jour les budgets côté client
      // sans toucher aux règles, ce test tombe avant que l'utilisateur ne
      // découvre un `permission-denied` incompréhensible au moment d'envoyer
      // sa photo.
      const photoUrlRuleCap = 140000;
      const coverUrlRuleCap = 280000;

      expect(
        ImageDataUrl.maxEncodedLength(ImageDataUrl.maxAvatarBytes),
        lessThanOrEqualTo(photoUrlRuleCap),
      );
      expect(
        ImageDataUrl.maxEncodedLength(ImageDataUrl.maxCoverBytes),
        lessThanOrEqualTo(coverUrlRuleCap),
      );
    });

    test('laisse une marge confortable sous la limite d’un document', () {
      // Un document Firestore plafonne à 1 Mio. Les deux images réunies
      // doivent en rester très loin : le profil est relu à chaque écran qui
      // affiche un avatar.
      const firestoreDocumentLimit = 1024 * 1024;
      final both =
          ImageDataUrl.maxEncodedLength(ImageDataUrl.maxAvatarBytes) +
          ImageDataUrl.maxEncodedLength(ImageDataUrl.maxCoverBytes);

      expect(both, lessThan(firestoreDocumentLimit ~/ 2));
    });
  });

  group('cohérence avec base64', () {
    test('la charge utile est un base64 standard, décodable par un tiers', () {
      // Le décodeur des règles n'existe pas, mais celui d'un navigateur ou
      // d'un outil d'export, si : l'encodage doit rester standard.
      final source = bytes(300);
      final url = ImageDataUrl.encode(source);
      final payload = url.substring(url.indexOf(',') + 1);

      expect(base64Decode(payload), equals(source));
    });
  });
}
