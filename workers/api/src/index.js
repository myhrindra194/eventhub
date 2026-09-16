// Point d'entrée du Worker Cloudflare « eventhub-api » : le seul code serveur
// d'EventHub, là où Cloud Functions exigerait le plan Blaze.
//
// Toutes les routes exigent l'ID token Firebase de l'appelant :
//   POST /v1/dispatch  { recipientId, notificationId }  push FCM d'une notification
//   POST /v1/welcome   {}                               mail de bienvenue (une fois)
//   POST /v1/contact   { subject, message }             message à la boîte de l'entreprise
//
// Configuration (voir wrangler.toml et docs/ARCHITECTURE.md) :
//   FIREBASE_PROJECT_ID       variable, « eventhub-d411f »
//   ALLOWED_ORIGINS           variable, origines web autorisées (CORS)
//   APP_ORIGIN                variable, lien ouvert par un push web et par le mail
//   COMPANY_EMAIL             variable, boîte de l'entreprise et expéditeur Brevo
//   FIREBASE_SERVICE_ACCOUNT  secret, JSON du compte de service
//   BREVO_API_KEY             secret, clé API Brevo (emails)

import { createAccessTokenProvider, createIdTokenVerifier, HttpError } from './google.js';
import { createFirestore, createMessenger, dispatch, purgeReceipts, validateRequest } from './dispatch.js';
import { createMailer, sendContact, sendWelcome, validateContact } from './mail.js';

/// Services construits une fois par isolat : leurs caches (clés publiques,
/// jeton OAuth) survivent ainsi d'une requête à l'autre.
let services = null;

function servicesFor(env) {
  if (services) return services;
  const projectId = env.FIREBASE_PROJECT_ID;
  const serviceAccount = JSON.parse(env.FIREBASE_SERVICE_ACCOUNT);
  const accessToken = createAccessTokenProvider({ serviceAccount });
  services = {
    verify: createIdTokenVerifier({ projectId }),
    firestore: createFirestore({ projectId, accessToken }),
    send: createMessenger({ projectId, accessToken }),
    mailer: createMailer({ apiKey: env.BREVO_API_KEY, sender: env.COMPANY_EMAIL }),
  };
  return services;
}

/// CORS pour la version web de l'app. Les applications mobiles n'envoient
/// pas d'en-tête `Origin` et ne sont pas concernées ; la vraie protection est
/// le jeton Firebase, pas l'origine.
function corsHeaders(request, env) {
  const origin = request.headers.get('origin');
  const allowed = (env.ALLOWED_ORIGINS ?? '').split(',').map((o) => o.trim()).filter(Boolean);
  if (!origin || !allowed.includes(origin)) return {};
  return {
    'access-control-allow-origin': origin,
    'access-control-allow-methods': 'POST, OPTIONS',
    'access-control-allow-headers': 'authorization, content-type',
    'access-control-max-age': '86400',
    vary: 'origin',
  };
}

const json = (status, body, headers = {}) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { 'content-type': 'application/json', ...headers },
  });

const ROUTES = new Set(['/v1/dispatch', '/v1/welcome', '/v1/contact']);

async function readJson(request) {
  try {
    return await request.json();
  } catch {
    throw new HttpError(400, 'bad_json');
  }
}

export async function handle(request, env, deps = null) {
  const cors = corsHeaders(request, env);
  const { pathname } = new URL(request.url);

  if (request.method === 'OPTIONS') return new Response(null, { status: 204, headers: cors });
  if (!ROUTES.has(pathname)) return json(404, { error: 'not_found' }, cors);
  if (request.method !== 'POST') return json(405, { error: 'method_not_allowed' }, cors);

  try {
    const { verify, firestore, send, mailer } = deps ?? servicesFor(env);
    const token = /^Bearer (.+)$/.exec(request.headers.get('authorization') ?? '')?.[1];
    if (!token) throw new HttpError(401, 'missing_token');
    const claims = await verify(token);
    const clock = deps?.now ? { now: deps.now } : {};

    let result;
    if (pathname === '/v1/dispatch') {
      result = await dispatch({
        callerId: claims.sub,
        request: validateRequest(await readJson(request)),
        firestore,
        send,
        appOrigin: env.APP_ORIGIN,
        ...clock,
      });
    } else if (pathname === '/v1/welcome') {
      result = await sendWelcome({ claims, firestore, mailer, appOrigin: env.APP_ORIGIN, ...clock });
    } else {
      result = await sendContact({
        claims,
        request: validateContact(await readJson(request)),
        firestore,
        mailer,
        companyEmail: env.COMPANY_EMAIL,
        ...clock,
      });
    }
    return json(200, result, cors);
  } catch (error) {
    if (error instanceof HttpError) return json(error.status, { error: error.code }, cors);
    console.error('Unexpected API failure', error?.stack ?? error);
    return json(500, { error: 'internal' }, cors);
  }
}

export default {
  fetch: (request, env) => handle(request, env),

  /// Déclencheur planifié (`[triggers] crons` dans wrangler.toml).
  async scheduled(_controller, env, ctx) {
    ctx.waitUntil(
      purgeReceipts({ firestore: servicesFor(env).firestore }).then((removed) =>
        console.log(`Purged ${removed} expired push receipts`),
      ),
    );
  },
};
