/// Public URLs of the product.
///
/// The web host is the Firebase Hosting site of the project: `/e/{id}` is
/// rendered by the `publicEventPage` Cloud Function (Open Graph preview for
/// people without the app) and opened directly by the app on Android through
/// App Links (see AndroidManifest.xml and hosting/public/.well-known).
abstract final class AppLinks {
  static const webHost = 'eventhub-d411f.web.app';
  static const supportEmail = 'support@eventhub.app';

  /// Public page of an event, e.g. `https://eventhub-d411f.web.app/e/abc123`.
  static String event(String eventId) =>
      'https://$webHost/e/${Uri.encodeComponent(eventId)}';

  /// The same link without its scheme, for display where space is tight.
  static String displayable(String url) =>
      url.replaceFirst(RegExp('^https?://'), '');
}
