import 'dart:convert';
import 'dart:typed_data';

/// Images embarquées directement dans un document Firestore, sous forme
/// d'URL `data:`.
///
/// **Pourquoi pas Cloud Storage.** Déposer un fichier dans un bucket exige le
/// plan Blaze, donc une carte bancaire : c'est précisément ce que le projet
/// refuse (voir `docs/ROADMAP.md`). Firestore, lui, tient sur le plan Spark.
/// Une photo de profil compressée y entre sans difficulté, à condition de la
/// borner — et c'est tout l'objet de ce fichier.
///
/// **Le coût assumé.** Un document Firestore ne peut pas dépasser 1 Mio, et
/// l'encodage base64 gonfle les octets d'un tiers. Chaque lecture du profil
/// retélécharge l'image, là où un bucket la servirait derrière un CDN avec un
/// cache HTTP. Les bornes ci-dessous sont donc choisies pour que le document
/// reste petit devant la limite : une photo de profil pèse moins qu'une page
/// de texte, et la couverture reste sous le quart du document.
///
/// Le jour où Blaze est activé, seul le producteur de ces chaînes change :
/// tout ce qui les affiche reçoit déjà une URL, `https:` ou `data:`.
abstract final class ImageDataUrl {
  static const _prefix = 'data:';

  /// Taille maximale des **octets d'image** d'un avatar, avant encodage.
  ///
  /// 96 Kio : à 512 px de côté et en JPEG de qualité moyenne, une photo de
  /// visage tient largement dessous.
  static const maxAvatarBytes = 96 * 1024;

  /// Idem pour une couverture, plus large donc plus lourde.
  static const maxCoverBytes = 192 * 1024;

  /// Longueur maximale de la chaîne stockée, reprise telle quelle par les
  /// règles de sécurité : base64 gonfle de 4/3, plus l'en-tête du préfixe.
  static int maxEncodedLength(int rawBytes) => (rawBytes * 4 / 3).ceil() + 64;

  static bool isDataUrl(String? url) => url != null && url.startsWith(_prefix);

  /// Encode [bytes] en URL `data:`. [mimeType] doit décrire le contenu réel :
  /// c'est lui que le décodeur d'images utilisera.
  static String encode(Uint8List bytes, {String mimeType = 'image/jpeg'}) =>
      '$_prefix$mimeType;base64,${base64Encode(bytes)}';

  /// Décode une URL `data:` produite par [encode].
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
