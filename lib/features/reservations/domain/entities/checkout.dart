/// A Stripe Checkout started by the `payments-checkout` Edge Function
/// (F-11): the page to open, and the held reservation to watch until the
/// Stripe webhook confirms it.
class CheckoutStart {
  const CheckoutStart({required this.url, required this.reservationId});

  final Uri url;
  final String reservationId;
}
