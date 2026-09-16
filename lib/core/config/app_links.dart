/// Les URL publiques du produit.
///
/// L’hôte web est le site Firebase Hosting du projet : `/e/{id}` est rendu
/// par la Cloud Function `publicEventPage` (aperçu Open Graph pour les gens
/// qui n’ont pas l’app) et ouvert directement par l’app sur Android via les
/// App Links (voir AndroidManifest.xml et hosting/public/.well-known).
abstract final class AppLinks {
  static const webHost = 'eventhub-d411f.web.app';
  static const supportEmail = 'support@eventhub.app';

  /// Page publique d’un événement, p. ex.
  /// `https://eventhub-d411f.web.app/e/abc123`.
  static String event(String eventId) =>
      'https://$webHost/e/${Uri.encodeComponent(eventId)}';

  /// Le même lien sans son schéma, pour l’afficher là où la place manque.
  static String displayable(String url) =>
      url.replaceFirst(RegExp('^https?://'), '');
}
