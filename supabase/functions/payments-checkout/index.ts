/**
 * POST {eventId, tierId} → {url, reservationId, expiresAt}
 *
 * Holds a seat of a paid ticket type for the caller (payments_hold_seat,
 * transactional) and opens a Stripe Checkout session for exactly the price
 * read from the database — the amount never comes from the client. An open
 * session for the same type is resumed instead of creating a second one.
 * If Stripe fails, the seat is released at once.
 */
import { HttpError, json, serve, uuidField } from '../_shared/http.ts';
import { PUBLIC_ORIGIN, stripe } from '../_shared/stripe.ts';
import { rpc } from '../_shared/supabase.ts';

/** Stripe accepts a session expiry of 30 minutes at the earliest. */
const HOLD_MINUTES = 31;

interface Hold {
  reservation_id: string;
  reused_url: string | null;
  price: number;
  currency: string;
  tier_name: string;
  event_title: string;
  email: string;
  expires_at: string;
}

serve('payments-checkout', { methods: ['POST'], auth: 'user' }, async ({ user, body, log }) => {
  const eventId = uuidField(body, 'eventId', 'Événement');
  const tierId = uuidField(body, 'tierId', 'Type de billet');

  const hold = await rpc<Hold>('payments_hold_seat', {
    p_user_id: user!.id,
    p_event_id: eventId,
    p_tier_id: tierId,
    p_hold_minutes: HOLD_MINUTES,
  });
  if (hold.reused_url) {
    return json({ url: hold.reused_url, reservationId: hold.reservation_id, expiresAt: hold.expires_at });
  }

  const reservation = encodeURIComponent(hold.reservation_id);
  const metadata = { reservationId: hold.reservation_id, eventId, tierId, userId: user!.id };
  try {
    const session = await stripe().checkout.sessions.create(
      {
        mode: 'payment',
        client_reference_id: hold.reservation_id,
        customer_email: hold.email,
        line_items: [{
          quantity: 1,
          price_data: {
            currency: hold.currency.toLowerCase(),
            // Minor units; MGA is zero-decimal for Stripe, as in the database.
            unit_amount: hold.price,
            product_data: { name: `${hold.event_title} — ${hold.tier_name}` },
          },
        }],
        metadata,
        payment_intent_data: { metadata },
        expires_at: Math.floor(new Date(hold.expires_at).getTime() / 1000),
        success_url: `${PUBLIC_ORIGIN}/pay/success?reservation=${reservation}`,
        cancel_url: `${PUBLIC_ORIGIN}/pay/cancel?reservation=${reservation}`,
        locale: 'fr',
      },
      { idempotencyKey: `checkout:${hold.reservation_id}:${hold.expires_at}` },
    );
    await rpc('payments_attach_session', {
      p_reservation_id: hold.reservation_id,
      p_session_id: session.id,
      p_url: session.url,
    });
    log.info('checkout opened', { reservationId: hold.reservation_id, amount: hold.price, currency: hold.currency });
    return json({ url: session.url, reservationId: hold.reservation_id, expiresAt: hold.expires_at });
  } catch (error) {
    await rpc('payments_release_hold', { p_reservation_id: hold.reservation_id, p_outcome: 'failed' });
    log.error('checkout session failed, seat released', { reservationId: hold.reservation_id, error: String(error) });
    throw new HttpError(503, 'paymentUnavailable', 'Le paiement est indisponible pour le moment. Réessayez plus tard.');
  }
});
