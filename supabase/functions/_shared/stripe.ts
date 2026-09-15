import { Stripe } from './deps.ts';
import { requireEnv } from './http.ts';

let client: Stripe | null = null;

/** Lazily built, so a function without the secret fails with a clean 503. */
export function stripe(): Stripe {
  client ??= new Stripe(requireEnv('STRIPE_SECRET_KEY'), {
    httpClient: Stripe.createFetchHttpClient(),
    maxNetworkRetries: 2,
    timeout: 15_000,
  });
  return client;
}

/** Web Crypto: webhook signatures are verified without Node's crypto. */
export const cryptoProvider = Stripe.createSubtleCryptoProvider();

/** Public origin of the site: Checkout success/cancel pages (App Links). */
export const PUBLIC_ORIGIN = Deno.env.get('PUBLIC_ORIGIN') ?? 'https://eventhub-d411f.web.app';

/**
 * Full refund of a payment. Idempotent twice over: Stripe dedupes on the
 * key, and an already refunded charge counts as done.
 */
export async function refundPaymentIntent(
  paymentIntentId: string,
  reservationId: string,
  context: string,
): Promise<string> {
  try {
    const refund = await stripe().refunds.create(
      { payment_intent: paymentIntentId, metadata: { reservationId, context } },
      { idempotencyKey: `refund:${reservationId}:${paymentIntentId}` },
    );
    return refund.id;
  } catch (error) {
    if ((error as { code?: string }).code === 'charge_already_refunded') {
      return 'already_refunded';
    }
    throw error;
  }
}
