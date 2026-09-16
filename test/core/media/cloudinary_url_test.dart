import 'package:eventhub/core/media/cloudinary_url.dart';
import 'package:flutter_test/flutter_test.dart';

/// Firestore ne garde que l'URL d'origine ; la variante téléchargée se
/// dérive à l'affichage. Une erreur ici ne casse rien de visible tout de
/// suite — elle fait simplement télécharger des images de 2 Mo dans des
/// vignettes de 40 px, ou casse l'affichage d'anciens liens. D'où ces tests.
void main() {
  const origin =
      'https://res.cloudinary.com/demo/image/upload/v1712/eventhub/avatars/a.jpg';

  group('reconnaissance', () {
    test('une URL de livraison Cloudinary est reconnue', () {
      expect(CloudinaryUrl.isCloudinary(origin), isTrue);
    });

    test('tout le reste ne l’est pas', () {
      for (final url in [
        null,
        '',
        'http://res.cloudinary.com/demo/image/upload/a.jpg',
        'https://images.example.com/image/upload/a.jpg',
        'https://res.cloudinary.com/demo/raw/upload/a.pdf',
        'data:image/png;base64,AAAA',
      ]) {
        expect(CloudinaryUrl.isCloudinary(url), isFalse, reason: url);
      }
    });
  });

  group('paliers', () {
    test('arrondit au palier supérieur en pixels physiques', () {
      // Un avatar de 40 px sur un écran ×3 occupe 120 px physiques.
      expect(CloudinaryUrl.bucketFor(40, 3), 160);
      expect(CloudinaryUrl.bucketFor(320, 1), 320);
      expect(CloudinaryUrl.bucketFor(321, 1), 640);
    });

    test('plafonne au plus grand palier', () {
      expect(CloudinaryUrl.bucketFor(2560, 2), CloudinaryUrl.widths.last);
    });
  });

  group('réécriture', () {
    test('insère la transformation juste après /image/upload/', () {
      expect(
        CloudinaryUrl.sized(origin, width: 640),
        'https://res.cloudinary.com/demo/image/upload/'
        'c_limit,w_640,f_webp,q_auto/v1712/eventhub/avatars/a.jpg',
      );
    });

    test('un avatar est un carré cadré sur le visage', () {
      expect(
        CloudinaryUrl.sized(origin, width: 160, square: true),
        contains('/image/upload/c_fill,g_face,w_160,h_160,f_webp,q_auto/'),
      );
    });

    test('laisse intacte une URL qui ne vient pas de Cloudinary', () {
      // Anciennes couvertures collées et photos `data:` doivent continuer
      // de s'afficher telles quelles.
      const legacy = 'https://images.example.com/cover.jpg?w=1600';
      expect(CloudinaryUrl.sized(legacy, width: 640), legacy);
    });
  });
}
