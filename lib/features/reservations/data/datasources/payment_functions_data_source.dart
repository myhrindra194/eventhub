import 'package:cloud_functions/cloud_functions.dart';
import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/errors/failure_exception.dart';
import 'package:eventhub/features/reservations/domain/entities/checkout.dart';

/// The payment callables (F-11). Amounts and availability are decided on
/// the server; the client only asks.
class PaymentFunctionsDataSource {
  const PaymentFunctionsDataSource(this._functions);

  final FirebaseFunctions _functions;

  Future<CheckoutStart> startCheckout({
    required String eventId,
    required String tierId,
  }) async {
    final result = await _functions
        .httpsCallable('createCheckoutSession')
        .call<Map<Object?, Object?>>({'eventId': eventId, 'tierId': tierId});
    final url = Uri.tryParse(result.data['url'] as String? ?? '');
    final reservationId = result.data['reservationId'];
    if (url == null || !url.isScheme('https') || reservationId is! String) {
      throw const FailureException(
        UnexpectedFailure(message: 'Réponse du paiement invalide.'),
      );
    }
    return CheckoutStart(url: url, reservationId: reservationId);
  }

  Future<void> cancelPending(String eventId) => _functions
      .httpsCallable('cancelPendingCheckout')
      .call<Object?>({'eventId': eventId});

  Future<void> refund(String eventId) => _functions
      .httpsCallable('cancelPaidReservation')
      .call<Object?>({'eventId': eventId});
}
