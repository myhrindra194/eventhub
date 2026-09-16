/// Lecture et réécriture des URL de livraison Cloudinary.
///
/// Firestore ne stocke que l'URL **d'origine** renvoyée par l'envoi
/// (`secure_url`). La taille servie, elle, dépend de l'écran : une carte de
/// 320 px sur un téléphone n'a pas à télécharger l'affiche de 2 048 px qu'une
/// fiche affiche sur un bureau. Cloudinary redimensionne à la volée quand on
/// insère une transformation juste après `/image/upload/` ; ce fichier est le
/// seul endroit qui connaît cette grammaire.
abstract final class CloudinaryUrl {
  static const _host = 'res.cloudinary.com';
  static const _uploadSegment = '/image/upload/';

  /// Largeurs servies. Arrondir au palier supérieur plutôt que demander la
  /// largeur exacte du widget, c'est garder un cache utile : sans paliers,
  /// chaque largeur de fenêtre sur le web produirait une nouvelle variante,
  /// donc une nouvelle transformation facturée sur le quota mensuel et un
  /// nouveau téléchargement.
  static const widths = [160, 320, 640, 960, 1280, 1920];

  /// Vrai pour une image livrée par Cloudinary — le seul hébergement que les
  /// règles Firestore acceptent pour une nouvelle image.
  static bool isCloudinary(String? url) {
    if (url == null) return false;
    final uri = Uri.tryParse(url);
    return uri != null &&
        uri.scheme == 'https' &&
        uri.host == _host &&
        uri.path.contains(_uploadSegment);
  }

  /// Le palier de [widths] qui couvre [logicalWidth] × [devicePixelRatio].
  static int bucketFor(double logicalWidth, double devicePixelRatio) {
    final physical = logicalWidth * devicePixelRatio;
    for (final width in widths) {
      if (width >= physical) return width;
    }
    return widths.last;
  }

  /// L'URL de [url] redimensionnée à [width] pixels physiques.
  ///
  /// Toute URL qui ne vient pas de Cloudinary — une ancienne couverture
  /// collée sous forme de lien, une image `data:` d'avant la migration — est
  /// rendue telle quelle : l'affichage ne doit jamais dépendre de la forme
  /// du lien stocké.
  ///
  /// Les paramètres, et pourquoi ceux-là :
  ///  * `c_limit` pour une couverture : réduit sans jamais agrandir ni
  ///    recadrer, le `BoxFit.cover` du widget se chargeant du cadrage ;
  ///  * `c_fill,g_face` pour un avatar ([square]) : un carré centré sur le
  ///    visage, que le cercle du widget rogne ensuite sans surprise ;
  ///  * `f_webp` plutôt que `f_auto` : `f_auto` peut servir de l'AVIF aux
  ///    navigateurs qui l'annoncent, que le moteur de rendu web de Flutter ne
  ///    sait pas toujours décoder. WebP est lu partout où Flutter tourne et
  ///    conserve la transparence ;
  ///  * `q_auto` : Cloudinary choisit la compression la plus forte qui reste
  ///    invisible à l'œil, image par image.
  static String sized(String url, {required int width, bool square = false}) {
    if (!isCloudinary(url)) return url;
    final at = url.indexOf(_uploadSegment) + _uploadSegment.length;
    final crop = square
        ? 'c_fill,g_face,w_$width,h_$width'
        : 'c_limit,w_$width';
    return '${url.substring(0, at)}$crop,f_webp,q_auto/${url.substring(at)}';
  }
}
