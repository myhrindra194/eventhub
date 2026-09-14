/// A Stripe Checkout started by `createCheckoutSession` (F-11): the page to
/// open, and the held reservation to watch until the webhook confirms it.
class CheckoutStart {
  const CheckoutStart({required this.url, required this.reservationId});

  final Uri url;
  final String reservationId;
}
