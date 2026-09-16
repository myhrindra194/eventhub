import 'dart:convert';
import 'dart:typed_data';

import 'package:eventhub/core/utils/image_data_url.dart';
import 'package:flutter_test/flutter_test.dart';

/// Les profils créés avant Cloudinary portent encore leur photo en `data:`.
/// L'application n'en écrit plus, mais elle doit continuer à les afficher :
/// ce fichier vérifie seulement que la lecture reste fidèle et tolérante.
void main() {
  group('reconnaissance', () {
    test('ne confond pas une URL distante avec une image embarquée', () {
      expect(ImageDataUrl.isDataUrl('https://example.com/a.jpg'), isFalse);
      expect(ImageDataUrl.isDataUrl(''), isFalse);
      expect(ImageDataUrl.isDataUrl(null), isFalse);
    });
  });

  group('décodage', () {
    test('rend les octets d’une image héritée', () {
      final source = Uint8List.fromList(
        List<int>.generate(300, (i) => i % 256),
      );
      final url = 'data:image/jpeg;base64,${base64Encode(source)}';
      expect(ImageDataUrl.decode(url), equals(source));
    });

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
}
