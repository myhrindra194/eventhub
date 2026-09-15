/**
 * POST {eventId} → {released}
 *
 * The buyer gives up before paying: the held seat goes back on sale and the
 * Stripe session is expired so it can no longer be paid. Should a payment
 * still slip through, the webhook finds the hold released and re-seats or
 * refunds it.
 */
import { json, serve, uuidField } from '../_shared/http.ts';
import { stripe } from '../_shared/stripe.ts';
import { rpc } from '../_shared/supabase.ts';

serve('payments-cancel', { methods: ['POST'], auth: 'user' }, async ({ user, body, log }) => {
  const eventId = uuidField(body, 'eventId', 'Événement');
  const outcome = await rpc<{ released: boolean; session_id?: string | null }>('payments_release_own_hold', {
    p_user_id: user!.id,
    p_event_id: eventId,
  });

  if (outcome.released && outcome.session_id) {
    await stripe().checkout.sessions.expire(outcome.session_id).catch((error: unknown) => {
      // Already expired or completed: the database state is what matters.
      log.warn('session expire failed', { sessionId: outcome.session_id, error: String(error) });
    });
  }
  return json({ released: outcome.released });
});
