// Accès Google sans SDK : vérification des jetons Firebase Auth et jeton
// d'accès du compte de service.
//
// Pourquoi pas `firebase-admin` : le SDK Admin s'appuie sur des modules
// Node (`http2`, `fs`, gRPC) absents du runtime Cloudflare Workers. Les deux
// opérations dont le Worker a besoin — vérifier une signature RS256 et en
// produire une — tiennent en quelques lignes de WebCrypto, disponible à
// l'identique dans Workers et dans Node (ce qui permet de tester ce fichier
// avec `node:test`, sans émulateur).

const JWKS_URL =
  'https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com';
const TOKEN_URL = 'https://oauth2.googleapis.com/token';

/// Les deux seuls périmètres dont le Worker a besoin : lire et écrire
/// Firestore (en contournant les règles, d'où la vérification applicative
/// dans dispatch.js) et envoyer par FCM. Rien d'autre du projet.
export const SCOPES = [
  'https://www.googleapis.com/auth/datastore',
  'https://www.googleapis.com/auth/firebase.messaging',
];

/// Tolérance d'horloge entre Cloudflare, Google et le téléphone.
const CLOCK_SKEW_SECONDS = 60;

const RSA = { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' };

export class HttpError extends Error {
  constructor(status, code, message = code) {
    super(message);
    this.status = status;
    this.code = code;
  }
}

// ------------------------------------------------------------- base64url

export function base64UrlEncode(bytes) {
  const view = bytes instanceof Uint8Array ? bytes : new Uint8Array(bytes);
  let binary = '';
  for (const byte of view) binary += String.fromCharCode(byte);
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

export function base64UrlDecode(text) {
  const padded = text.replace(/-/g, '+').replace(/_/g, '/').padEnd(Math.ceil(text.length / 4) * 4, '=');
  const binary = atob(padded);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes;
}

const utf8 = new TextEncoder();
const jsonPart = (value) => base64UrlEncode(utf8.encode(JSON.stringify(value)));
const decodeJson = (part) => JSON.parse(new TextDecoder().decode(base64UrlDecode(part)));

// ------------------------------------------------ jetons Firebase Auth

/// Clés publiques de Firebase Auth, gardées en mémoire tant que Google le
/// permet (`Cache-Control: max-age`). Un isolat Worker vit plusieurs minutes :
/// sans ce cache, chaque notification coûterait une requête de plus, et le
/// plan gratuit plafonne le nombre de sous-requêtes par invocation.
export function createIdTokenVerifier({ projectId, fetchImpl = fetch, now = () => Date.now() }) {
  let cache = { keys: null, expiresAt: 0 };

  async function publicKey(kid) {
    if (!cache.keys || now() >= cache.expiresAt) {
      const response = await fetchImpl(JWKS_URL);
      if (!response.ok) throw new HttpError(503, 'jwks_unavailable');
      const maxAge = /max-age=(\d+)/.exec(response.headers.get('cache-control') ?? '');
      const { keys } = await response.json();
      cache = { keys, expiresAt: now() + (maxAge ? Number(maxAge[1]) : 3600) * 1000 };
    }
    const jwk = cache.keys.find((key) => key.kid === kid);
    // Clé inconnue : soit un jeton forgé, soit une rotation que le cache
    // n'a pas encore vue. On refuse ; le client obtiendra un jeton signé par
    // une clé publiée à sa prochaine tentative.
    if (!jwk) throw new HttpError(401, 'unknown_key');
    return crypto.subtle.importKey('jwk', jwk, RSA, false, ['verify']);
  }

  /// Renvoie les revendications vérifiées du jeton (`sub`, `email`,
  /// `email_verified`, `name`…), ou lève une HttpError 401.
  ///
  /// Chaque contrôle correspond à une exigence documentée par Firebase pour
  /// vérifier un ID token sans SDK : algorithme, signature, audience,
  /// émetteur, expiration, date d'émission et sujet non vide.
  return async function verify(token) {
    const parts = typeof token === 'string' ? token.split('.') : [];
    if (parts.length !== 3) throw new HttpError(401, 'malformed_token');

    let header;
    let payload;
    try {
      header = decodeJson(parts[0]);
      payload = decodeJson(parts[1]);
    } catch {
      throw new HttpError(401, 'malformed_token');
    }
    if (header.alg !== 'RS256' || typeof header.kid !== 'string') {
      throw new HttpError(401, 'bad_algorithm');
    }

    const valid = await crypto.subtle.verify(
      RSA,
      await publicKey(header.kid),
      base64UrlDecode(parts[2]),
      utf8.encode(`${parts[0]}.${parts[1]}`),
    );
    if (!valid) throw new HttpError(401, 'bad_signature');

    const seconds = Math.floor(now() / 1000);
    if (payload.aud !== projectId) throw new HttpError(401, 'bad_audience');
    if (payload.iss !== `https://securetoken.google.com/${projectId}`) {
      throw new HttpError(401, 'bad_issuer');
    }
    if (typeof payload.exp !== 'number' || payload.exp <= seconds - CLOCK_SKEW_SECONDS) {
      throw new HttpError(401, 'expired_token');
    }
    if (typeof payload.iat !== 'number' || payload.iat > seconds + CLOCK_SKEW_SECONDS) {
      throw new HttpError(401, 'future_token');
    }
    if (typeof payload.sub !== 'string' || payload.sub.length === 0 || payload.sub.length > 128) {
      throw new HttpError(401, 'bad_subject');
    }
    return payload;
  };
}

// ---------------------------------------------- compte de service Google

function pemToDer(pem) {
  const body = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, '')
    .replace(/-----END PRIVATE KEY-----/, '')
    .replace(/\s+/g, '');
  return base64UrlDecode(body.replace(/\+/g, '-').replace(/\//g, '_'));
}

/// Jeton d'accès OAuth du compte de service, mis en cache jusqu'à une minute
/// avant son expiration (une heure).
///
/// Le compte de service est le fichier JSON « Générer une nouvelle clé
/// privée » de la console Firebase, stocké en secret Cloudflare
/// (`wrangler secret put FIREBASE_SERVICE_ACCOUNT`). Sa génération est
/// gratuite sur le plan Spark.
export function createAccessTokenProvider({ serviceAccount, fetchImpl = fetch, now = () => Date.now() }) {
  let cached = { token: null, expiresAt: 0 };
  let signingKey = null;

  return async function accessToken() {
    if (cached.token && now() < cached.expiresAt - 60_000) return cached.token;

    signingKey ??= await crypto.subtle.importKey(
      'pkcs8',
      pemToDer(serviceAccount.private_key),
      RSA,
      false,
      ['sign'],
    );
    const iat = Math.floor(now() / 1000);
    const unsigned = `${jsonPart({ alg: 'RS256', typ: 'JWT' })}.${jsonPart({
      iss: serviceAccount.client_email,
      scope: SCOPES.join(' '),
      aud: TOKEN_URL,
      iat,
      exp: iat + 3600,
    })}`;
    const signature = await crypto.subtle.sign(RSA, signingKey, utf8.encode(unsigned));

    const response = await fetchImpl(TOKEN_URL, {
      method: 'POST',
      headers: { 'content-type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        assertion: `${unsigned}.${base64UrlEncode(signature)}`,
      }),
    });
    if (!response.ok) {
      // Jamais le corps : il peut citer l'adresse du compte de service.
      console.error(`Google OAuth refused the service account (${response.status})`);
      throw new HttpError(503, 'google_auth_unavailable');
    }
    const { access_token: token, expires_in: expiresIn } = await response.json();
    cached = { token, expiresAt: now() + expiresIn * 1000 };
    return token;
  };
}
