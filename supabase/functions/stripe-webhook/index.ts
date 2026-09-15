/**
 * Stripe → EventHub. Endpoint to declare in the Stripe dashboard:
 *   https://<project-ref>.supabase.co/functions/v1/stripe-webhook
 * Events: checkout.session.completed, checkout.session.async_payment_succeeded,
 *         checkout.session.expired, checkout.session.async_payment_failed.
 *
 * The signature is verified on the exact raw body. Every branch is
 * idempotent in the database (a replay confirms nothing twice, releases
 * nothing twice). Any failure answers 5xx, and Stripe retries.
 */
import { HttpError, isUuid, json, requireEnv, serve } from '../_shared/http.ts';
import type { Stripe } from '../_shared/deps.ts';
import { cryptoProvider, refundPaymentIntent, stripe } from '../_shared/stripe.ts';
import { rpc } from '../_shared/supabase.ts';

serve('stripe-webhook', { methods: ['POST'], auth: 'public', rawBody: true }, async ({ request, log }) => {
  const signature = request.headers.get('stripe-signature');
  if (!signature) {
    throw new HttpError(400, 'invalidSignature', 'Signature absente.');
  }
  const payload = await request.text();

  let event: Stripe.Event;
  try {
    event = await stripe().webhooks.constructEventAsync(
      payload,
      signature,
      requireEnv('STRIPE_WEBHOOK_SECRET'),
      undefined,
      cryptoProvider,
    );
  } catch (error) {
    if (error instanceof HttpError) throw error;
    throw new HttpError(400, 'invalidSignature', 'Signature invalide.');
  }

  const session = event.data.object as Stripe.Checkout.Session;
  const reservationId = session?.metadata?.reservationId;
  if (!isUuid(reservationId)) {
    return json({ received: true, ignored: true });
  }

  switch (event.type) {
    case 'checkout.session.completed':
    case 'checkout.session.async_payment_succeeded': {
      if (session.payment_status !== 'paid') break;
      const intent = typeof session.payment_intent === 'string'
        ? session.payment_intent
        : session.payment_intent?.id ?? null;
      const outcome = await rpc<string>('payments_fulfill', {
        p_reservation_id: reservationId,
        p_payment_intent_id: intent,
        p_amount: session.amount_total ?? 0,
        p_currency: session.currency ?? 'eur',
        p_session_id: session.id,
      });
      // Paid, but the seat is gone: refund now, never charge without a ticket.
      if (outcome === 'refund' && intent) {
        const refundId = await refundPaymentIntent(intent, reservationId, 'no_seat');
        await rpc('payments_mark_refunded', {
          p_reservation_id: reservationId,
          p_payment_intent_id: intent,
          p_refund_id: refundId,
        });
      }
      log.info('checkout completed', { eventId: event.id, reservationId, outcome });
      break;
    }
    case 'checkout.session.expired':
    case 'checkout.session.async_payment_failed': {
      const released = await rpc<boolean>('payments_release_hold', {
        p_reservation_id: reservationId,
        p_outcome: event.type === 'checkout.session.expired' ? 'expired' : 'failed',
      });
      log.info('checkout ended without payment', { eventId: event.id, reservationId, released });
      break;
    }
    default:
      break;
  }
  return json({ received: true });
});
