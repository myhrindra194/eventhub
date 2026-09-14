/// Outward-facing addresses of the product.
///
/// Distinct from `AppRoutes`: routes are locations *inside* the app, these
/// are strings that leave it — pasted in a chat, printed on a flyer — and
/// therefore must stay stable long after an in-app path has been renamed.
abstract final class AppLinks {
  static const webHost = 'eventhub.app';
  static const supportEmail = 'support@eventhub.app';

  /// Public page of an event, e.g. `https://eventhub.app/e/flutter-meetup`.
  static String event(String eventId) =>
      'https://$webHost/e/${Uri.encodeComponent(eventId)}';

  /// The same link without its scheme, for display where space is tight.
  static String displayable(String url) =>
      url.replaceFirst(RegExp('^https?://'), '');
}
