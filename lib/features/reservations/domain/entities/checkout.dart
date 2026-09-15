/// A paid checkout (F-11): the payment page to open, and the held
/// reservation to follow until the payment is confirmed.
///
/// Never produced on the Spark plan — there is no server to create a
/// payment session or receive its webhook, so `startCheckout` answers
/// `ReservationPolicy.paymentUnavailable`. The type stays so the contract is
/// ready for a payment backend.
class CheckoutStart {
  const CheckoutStart({required this.url, required this.reservationId});

  final Uri url;
  final String reservationId;
}
