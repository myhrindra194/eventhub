import 'dart:convert';
import 'dart:typed_data';

/// Lecture des images **héritées** embarquées dans un document Firestore
/// sous forme d'URL `data:`.
///
/// Avant Cloudinary, faute de Cloud Storage sur le plan Spark, la photo et
/// la couverture d'un profil voyageaient en base64 dans `users/{uid}`.
/// L'application n'en produit plus : chaque nouvelle image part vers
/// Cloudinary et seul son lien est stocké. Mais les profils existants en
/// portent encore, et les règles les laissent en place tant que leur
/// propriétaire ne les remplace pas. Ce décodeur existe donc pour une seule
/// raison : qu'une photo d'avant la migration continue de s'afficher.
///
/// Le jour où plus aucun document n'en contient, ce fichier se supprime avec
/// les deux branches `isDataUrl` des widgets d'affichage.
abstract final class ImageDataUrl {
  static const _prefix = 'data:';

  static bool isDataUrl(String? url) => url != null && url.startsWith(_prefix);

  /// Décode une URL `data:image/…;base64,…`.
  ///
  /// Renvoie `null` plutôt que de lever pour une chaîne malformée : une image
  /// illisible doit dégrader vers le repli visuel du composant, jamais faire
  /// tomber l'écran qui l'affiche.
  static Uint8List? decode(String url) {
    if (!isDataUrl(url)) return null;
    final comma = url.indexOf(',');
    if (comma < 0) return null;
    try {
      return base64Decode(url.substring(comma + 1));
    } on FormatException {
      return null;
    }
  }
}
