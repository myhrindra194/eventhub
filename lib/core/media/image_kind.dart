/// Les trois usages d'une image dans EventHub.
///
/// Chaque usage fixe ce qui doit rester cohérent d'un bout à l'autre de la
/// chaîne : la taille à laquelle l'appareil recompresse avant l'envoi, le
/// dossier Cloudinary où le fichier atterrit, et la manière de le recadrer à
/// l'affichage. Les réunir ici évite qu'un écran envoie une couverture de
/// 4 000 px dans le dossier des avatars parce que deux constantes ont divergé.
enum ImageKind {
  /// Photo de profil, toujours affichée dans un cercle.
  avatar(folder: 'avatars', maxSide: 1024, faceCrop: true),

  /// Bandeau en tête du profil.
  profileCover(folder: 'profile-covers', maxSide: 2048, faceCrop: false),

  /// Affiche d'un événement, affichée en 16:9 dans les cartes et la fiche.
  eventCover(folder: 'event-covers', maxSide: 2048, faceCrop: false);

  const ImageKind({
    required this.folder,
    required this.maxSide,
    required this.faceCrop,
  });

  /// Sous-dossier de `eventhub/` dans la médiathèque Cloudinary. Il sert au
  /// tri et au nettoyage à la main, jamais à l'autorisation : un envoi non
  /// signé peut viser le dossier qu'il veut (voir `docs/SECURITY.md`).
  final String folder;

  /// Plus grand côté demandé au sélecteur. Au-delà, les pixels ne servent à
  /// aucun écran — un moniteur 4K n'affiche pas une couverture à plus de
  /// 2 048 px de large dans la mise en page — et ne feraient que ralentir
  /// l'envoi sur une connexion mobile.
  final double maxSide;

  /// Recadrer sur le visage plutôt qu'au centre : pour un avatar, un cadrage
  /// centré coupe souvent le menton ou le front d'une photo en pied.
  final bool faceCrop;
}
