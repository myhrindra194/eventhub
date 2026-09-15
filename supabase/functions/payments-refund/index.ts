/**
 * POST {eventId} → {refunded}
 *
 * "Annuler et être remboursé": a paid, active ticket, before the event
 * starts (checked by payments_begin_refund). Stripe refunds first; only then
 * is the ticket cancelled and the seat put back on sale — never the other
 * way round, so a failed refund leaves the buyer with their ticket.
 */
import { json, serve, uuidField } from '../_shared/http.ts';
import { refundPaymentIntent } from '../_shared/stripe.ts';
import { rpc } from '../_shared/supabase.ts';

serve('payments-refund', { methods: ['POST'], auth: 'user' }, async ({ user, body, log }) => {
  const eventId = uuidField(body, 'eventId', 'Événement');
  const payment = await rpc<{ reservation_id: string; payment_intent_id: string }>('payments_begin_refund', {
    p_user_id: user!.id,
    p_event_id: eventId,
  });

  const refundId = await refundPaymentIntent(payment.payment_intent_id, payment.reservation_id, 'participant');
  const cancelled = await rpc<boolean>('payments_complete_refund', {
    p_reservation_id: payment.reservation_id,
    p_refund_id: refundId,
  });
  log.info('ticket refunded', { reservationId: payment.reservation_id, refundId, cancelled });
  return json({ refunded: true });
});
