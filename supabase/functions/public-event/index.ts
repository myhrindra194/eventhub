/**
 * GET /functions/v1/public-event/<eventId>
 *
 * The public face of a shared link (F-08): only what the organizer published
 * to be shared, nothing about attendees. JSON by default — the Hosting page
 * `/e/<id>` renders it — and a full HTML page with Open Graph tags when the
 * caller asks for `text/html` (link-preview crawlers). Supabase serves HTML
 * from Edge Functions on a custom domain only; on `*.supabase.co` the
 * Hosting page is the path people and crawlers take.
 */
import { HttpError, isUuid, json, serve } from '../_shared/http.ts';
import { PUBLIC_ORIGIN } from '../_shared/stripe.ts';
import { rpc } from '../_shared/supabase.ts';

interface Snapshot {
  id: string;
  title: string;
  description: string;
  category: string;
  starts_at: string;
  location: string;
  organizer_name: string;
  image_url: string | null;
  capacity: number;
  available_places: number;
  currency: 'EUR' | 'USD' | 'MGA' | null;
  prices: number[];
}

const TIME_ZONE = 'Indian/Antananarivo';
const CATEGORY_LABELS: Record<string, string> = {
  conference: 'Conférence', meetup: 'Meetup', workshop: 'Atelier', concert: 'Concert',
  sport: 'Sport', culture: 'Culture', other: 'Événement',
};

serve('public-event', { methods: ['GET', 'HEAD'], auth: 'public' }, async ({ request }) => {
  const id = decodeURIComponent(new URL(request.url).pathname.split('/').filter(Boolean).pop() ?? '');
  if (!isUuid(id)) {
    throw new HttpError(404, 'notFound', "Cet événement n'existe plus.");
  }
  const event = await rpc<Snapshot | null>('public_event_snapshot', { p_event_id: id });
  if (!event) {
    throw new HttpError(404, 'notFound', "Cet événement n'existe plus.");
  }

  const view = present(event, Date.now());
  const cache = { 'Cache-Control': 'public, max-age=300, s-maxage=600' };
  if ((request.headers.get('accept') ?? '').includes('text/html')) {
    return new Response(renderPage(event, view), {
      headers: { 'Content-Type': 'text/html; charset=utf-8', ...cache },
    });
  }
  return json({ ...view, id: event.id, title: event.title, description: event.description,
    location: event.location, organizerName: event.organizer_name, imageUrl: event.image_url }, 200, cache);
});

function present(event: Snapshot, now: number) {
  const startsAt = new Date(event.starts_at);
  const day = new Intl.DateTimeFormat('fr-FR', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric', timeZone: TIME_ZONE }).format(startsAt);
  const hour = new Intl.DateTimeFormat('fr-FR', { hour: '2-digit', minute: '2-digit', timeZone: TIME_ZONE }).format(startsAt);
  const available = Math.max(0, event.available_places);
  const past = startsAt.getTime() <= now;
  const s = available > 1 ? 's' : '';
  const status = past
    ? 'Événement passé'
    : available === 0
      ? "Complet — liste d'attente dans l'application"
      : `${available} place${s} sur ${event.capacity} encore libre${s}`;
  return {
    category: CATEGORY_LABELS[event.category] ?? 'Événement',
    day,
    hour,
    status,
    past,
    soldOut: available === 0,
    price: priceSummary(event.prices, event.currency ?? 'EUR'),
    url: `${PUBLIC_ORIGIN}/e/${encodeURIComponent(event.id)}`,
  };
}

/** `15,00 €`, `15 000 MGA`: the currency's own number of decimals. */
export function formatMoney(amount: number, currency: string): string {
  const zeroDecimal = currency.toUpperCase() === 'MGA';
  return new Intl.NumberFormat('fr-FR', {
    style: 'currency',
    currency: currency.toUpperCase(),
    minimumFractionDigits: zeroDecimal ? 0 : 2,
    maximumFractionDigits: zeroDecimal ? 0 : 2,
  }).format(zeroDecimal ? amount : amount / 100);
}

export function priceSummary(prices: number[], currency: string): string {
  const paid = prices.filter((p) => p > 0);
  if (paid.length === 0) return 'Entrée gratuite';
  const min = Math.min(...paid);
  if (paid.length < prices.length) return `Gratuit ou payant, dès ${formatMoney(min, currency)}`;
  return paid.every((p) => p === min) ? formatMoney(min, currency) : `Dès ${formatMoney(min, currency)}`;
}

function escapeHtml(value: unknown): string {
  return String(value ?? '')
    .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;').replace(/'/g, '&#39;');
}

function renderPage(event: Snapshot, view: ReturnType<typeof present>): string {
  const e = escapeHtml;
  const summary = `${view.day} à ${view.hour} · ${event.location} · ${view.price} · ${view.status}`;
  const image = event.image_url?.startsWith('https://') ? event.image_url : null;
  return `<!doctype html>
<html lang="fr"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>${e(event.title)} · EventHub</title>
<meta name="description" content="${e(summary)}"><link rel="canonical" href="${e(view.url)}">
<meta property="og:type" content="website"><meta property="og:site_name" content="EventHub"><meta property="og:locale" content="fr_FR">
<meta property="og:url" content="${e(view.url)}"><meta property="og:title" content="${e(event.title)}"><meta property="og:description" content="${e(summary)}">
${image ? `<meta property="og:image" content="${e(image)}">` : ''}<meta name="twitter:card" content="${image ? 'summary_large_image' : 'summary'}">
</head><body><main><p>EventHub</p><h1>${e(event.title)}</h1><p>${e(summary)}</p>
<p>${e(event.description).replace(/\n/g, '<br>')}</p><p><a href="${e(view.url)}">Voir l'événement</a></p></main></body></html>`;
}
