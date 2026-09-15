import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/errors/failure_exception.dart';
import 'package:eventhub/core/supabase/db.dart';
import 'package:eventhub/features/reservations/domain/entities/checkout.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The payment Edge Functions (F-11). Amounts and availability are decided
/// on the server from the database; the client only names the event and
/// the ticket type.
///
/// A refusal (non-2xx) throws a `FunctionException` whose JSON body carries
/// the business rule; `ErrorMapper` turns it into the same failure a
/// database function would give.
class PaymentFunctionsDataSource {
  const PaymentFunctionsDataSource(this._functions);

  final FunctionsClient _functions;

  /// Holds a paid seat and opens (or resumes) its Stripe Checkout session.
  Future<CheckoutStart> startCheckout({
    required String eventId,
    required String tierId,
  }) async {
    final response = await _functions.invoke(
      EdgeFunctions.paymentsCheckout,
      body: {'eventId': eventId, 'tierId': tierId},
    );
    final data = response.data;
    final url = data is Map ? Uri.tryParse('${data['url'] ?? ''}') : null;
    final reservationId = data is Map ? data['reservationId'] : null;
    // The page is opened in the browser: anything but a Stripe https URL is
    // a broken response, not something to launch.
    if (url == null || !url.isScheme('https') || reservationId is! String) {
      throw const FailureException(
        UnexpectedFailure(message: 'Réponse du paiement invalide.'),
      );
    }
    return CheckoutStart(url: url, reservationId: reservationId);
  }

  /// Gives up a held seat. `{released: false}` means there was nothing left
  /// to release (hold expired, or paid meanwhile): not an error, the
  /// reservation stream shows the real state.
  Future<void> cancelPending(String eventId) async {
    await _functions.invoke(
      EdgeFunctions.paymentsCancel,
      body: {'eventId': eventId},
    );
  }

  /// Refunds a paid ticket; Stripe first, then the seat is released.
  Future<void> refund(String eventId) async {
    await _functions.invoke(
      EdgeFunctions.paymentsRefund,
      body: {'eventId': eventId},
    );
  }
}
