/// Un paiement en ligne (F-11) : la page de paiement à ouvrir, et la
/// réservation retenue à suivre jusqu’à la confirmation du paiement.
///
/// Jamais produit sur le plan Spark — aucun serveur n’est là pour créer une
/// session de paiement ni recevoir son webhook, si bien que `startCheckout`
/// répond `ReservationPolicy.paymentUnavailable`. Le type demeure pour que
/// le contrat soit prêt pour un backend de paiement.
class CheckoutStart {
  const CheckoutStart({required this.url, required this.reservationId});

  final Uri url;
  final String reservationId;
}
