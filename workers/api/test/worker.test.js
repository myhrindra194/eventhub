// Tests du Worker sans réseau ni compte Google : une vraie paire de clés RSA
// signe des ID tokens de test et le compte de service, et un faux `fetch`
// joue Google (clés publiques, OAuth), Firestore et FCM.

import assert from 'node:assert/strict';
import { beforeEach, describe, test } from 'node:test';

import { base64UrlEncode, createAccessTokenProvider, createIdTokenVerifier } from '../src/google.js';
import { buildMessage, createFirestore, createMessenger, MAX_AGE_MS, purgeReceipts, RECEIPT_LIFETIME_MS } from '../src/dispatch.js';
import { handle } from '../src/index.js';
import { createMailer, CONTACT_COOLDOWN_MS, escapeHtml } from '../src/mail.js';

const PROJECT = 'eventhub-d411f';
const NOW = Date.parse('2026-09-16T12:00:00Z');
const RSA = { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' };
const utf8 = new TextEncoder();

const keys = await crypto.subtle.generateKey(
  { ...RSA, modulusLength: 2048, publicExponent: new Uint8Array([1, 0, 1]) },
  true,
  ['sign', 'verify'],
);
const jwk = { ...(await crypto.subtle.exportKey('jwk', keys.publicKey)), kid: 'k1', alg: 'RS256', use: 'sig' };
const pkcs8 = Buffer.from(await crypto.subtle.exportKey('pkcs8', keys.privateKey)).toString('base64');
const serviceAccount = {
  client_email: 'push@eventhub-d411f.iam.gserviceaccount.com',
  private_key: `-----BEGIN PRIVATE KEY-----\n${pkcs8.match(/.{1,64}/g).join('\n')}\n-----END PRIVATE KEY-----\n`,
};

async function idToken(overrides = {}, { kid = 'k1' } = {}) {
  const seconds = Math.floor(NOW / 1000);
  const part = (value) => base64UrlEncode(utf8.encode(JSON.stringify(value)));
  const unsigned = `${part({ alg: 'RS256', kid })}.${part({
    aud: PROJECT,
    iss: `https://securetoken.google.com/${PROJECT}`,
    sub: 'organizer-1',
    iat: seconds - 30,
    exp: seconds + 3000,
    ...overrides,
  })}`;
  const signature = await crypto.subtle.sign(RSA, keys.privateKey, utf8.encode(unsigned));
  return `${unsigned}.${base64UrlEncode(signature)}`;
}

/// Un Google, un Firestore et un FCM en mémoire, derrière un seul `fetch`.
function fakeGoogle() {
  const state = {
    docs: new Map(),
    sent: [],
    deadTokens: new Set(),
    calls: [],
    mails: [],
  };
  const reply = (status, body, headers = {}) =>
    new Response(body === undefined ? null : JSON.stringify(body), { status, headers });

  async function fetchImpl(input, init = {}) {
    const url = new URL(typeof input === 'string' ? input : input.url);
    const method = init.method ?? 'GET';
    state.calls.push(`${method} ${url.host}${url.pathname}`);

    if (url.host === 'www.googleapis.com') {
      return reply(200, { keys: [jwk] }, { 'cache-control': 'public, max-age=600' });
    }
    if (url.host === 'oauth2.googleapis.com') {
      const assertion = new URLSearchParams(init.body.toString()).get('assertion');
      assert.equal(assertion.split('.').length, 3);
      return reply(200, { access_token: 'ya29.test', expires_in: 3600 });
    }
    if (url.host === 'api.brevo.com') {
      assert.equal(init.headers['api-key'], 'brevo-test');
      state.mails.push(JSON.parse(init.body));
      return reply(201, { messageId: '<1@brevo>' });
    }
    if (url.host === 'fcm.googleapis.com') {
      const { message } = JSON.parse(init.body);
      if (state.deadTokens.has(message.token)) {
        return reply(404, { error: { details: [{ errorCode: 'UNREGISTERED' }] } });
      }
      state.sent.push(message);
      return reply(200, { name: 'projects/x/messages/1' });
    }
    if (url.host === 'firestore.googleapis.com') {
      assert.equal(init.headers.authorization, 'Bearer ya29.test');
      const path = decodeURIComponent(url.pathname.split('/documents/')[1] ?? '');
      if (url.pathname.endsWith(':runQuery')) {
        const { structuredQuery } = JSON.parse(init.body);
        const before = Date.parse(structuredQuery.where.fieldFilter.value.timestampValue);
        const rows = [...state.docs.entries()]
          .filter(([key, doc]) => key.startsWith('pushReceipts/') && Date.parse(doc.fields.expiresAt.timestampValue) < before)
          .slice(0, structuredQuery.limit)
          .map(([key]) => ({ document: { name: `projects/${PROJECT}/databases/(default)/documents/${key}` } }));
        return reply(200, rows.length ? rows : [{ readTime: 'now' }]);
      }
      if (url.pathname.endsWith(':commit')) {
        for (const write of JSON.parse(init.body).writes) state.docs.delete(write.delete.split('/documents/')[1]);
        return reply(200, {});
      }
      if (method === 'POST') {
        const id = `${path}/${url.searchParams.get('documentId')}`;
        if (state.docs.has(id)) return reply(409, { error: { status: 'ALREADY_EXISTS' } });
        state.docs.set(id, { fields: JSON.parse(init.body).fields });
        return reply(200, {});
      }
      if (method === 'PATCH') {
        state.docs.set(path, { fields: JSON.parse(init.body).fields });
        return reply(200, {});
      }
      if (method === 'DELETE') {
        state.docs.delete(path);
        return reply(200, {});
      }
      if (url.searchParams.has('pageSize')) {
        const documents = [...state.docs.entries()]
          .filter(([key]) => key.startsWith(`${path}/`) && !key.slice(path.length + 1).includes('/'))
          .map(([key, doc]) => ({ name: `projects/${PROJECT}/databases/(default)/documents/${key}`, ...doc }));
        return reply(200, { documents });
      }
      const doc = state.docs.get(path);
      return doc ? reply(200, doc) : reply(404, { error: { status: 'NOT_FOUND' } });
    }
    throw new Error(`Unexpected fetch ${url}`);
  }
  return { state, fetchImpl };
}

const str = (value) => (value == null ? { nullValue: null } : { stringValue: value });

function seedNotice(state, { id = 'booking_e1_p1_1', recipient = 'organizer-1', actor = 'organizer-1', type = 'booking', ageMs = 5_000 } = {}) {
  state.docs.set(`users/${recipient}/notifications/${id}`, {
    createTime: new Date(NOW - ageMs).toISOString(),
    fields: {
      type: str(type),
      title: str('Nouvelle réservation'),
      body: str('Soa a réservé une place pour « Flutter Meetup ».'),
      eventId: str('e1'),
      reservationId: str(null),
      actorId: str(actor),
    },
  });
}

function seedDevice(state, uid, id, token) {
  state.docs.set(`users/${uid}/devices/${id}`, { fields: { token: str(token), platform: str('android') } });
}

describe('dispatch endpoint', () => {
  let google;
  let deps;
  const env = {
    FIREBASE_PROJECT_ID: PROJECT,
    ALLOWED_ORIGINS: 'http://localhost:5050',
    APP_ORIGIN: 'https://eventhub-d411f.web.app',
    COMPANY_EMAIL: 'contact@eventhub.example',
  };

  beforeEach(() => {
    google = fakeGoogle();
    const now = () => NOW;
    const accessToken = createAccessTokenProvider({ serviceAccount, fetchImpl: google.fetchImpl, now });
    const firestore = createFirestore({ projectId: PROJECT, accessToken, fetchImpl: google.fetchImpl });
    deps = {
      verify: createIdTokenVerifier({ projectId: PROJECT, fetchImpl: google.fetchImpl, now }),
      firestore,
      send: createMessenger({ projectId: PROJECT, accessToken, fetchImpl: google.fetchImpl }),
      mailer: createMailer({ apiKey: 'brevo-test', sender: 'contact@eventhub.example', fetchImpl: google.fetchImpl }),
      // Horloge figée : l'âge des notifications se mesure contre NOW.
      now,
    };
  });

  async function call(body, { token, origin, path = '/v1/dispatch', envOverride = {} } = {}) {
    const headers = { 'content-type': 'application/json' };
    if (token !== null) headers.authorization = `Bearer ${token ?? (await idToken())}`;
    if (origin) headers.origin = origin;
    const response = await handle(
      new Request(`https://api.example${path}`, { method: 'POST', headers, body: JSON.stringify(body) }),
      { ...env, ...envOverride },
      deps,
    );
    return { status: response.status, body: await response.json(), headers: response.headers };
  }

  test('relaie une notification récente à chaque appareil du destinataire', async () => {
    seedNotice(google.state, { recipient: 'organizer-1', actor: 'participant-1' });
    seedDevice(google.state, 'organizer-1', 'phone', 'token-phone');
    seedDevice(google.state, 'organizer-1', 'tablet', 'token-tablet');

    const { status, body } = await call(
      { recipientId: 'organizer-1', notificationId: 'booking_e1_p1_1' },
      { token: await idToken({ sub: 'participant-1' }) },
    );

    assert.equal(status, 200);
    assert.deepEqual(body, { status: 'sent', delivered: 2, pruned: 0 });
    assert.deepEqual(google.state.sent.map((m) => m.token).sort(), ['token-phone', 'token-tablet']);
    const [message] = google.state.sent;
    assert.equal(message.notification.title, 'Nouvelle réservation');
    // Les clés que lit NotificationRoute pour ouvrir le bon écran.
    assert.deepEqual(message.data, { type: 'booking', notificationId: 'booking_e1_p1_1', eventId: 'e1' });
    assert.equal(message.android.notification.channel_id, 'eventhub_default');
  });

  test('ne renvoie jamais deux fois la même notification', async () => {
    seedNotice(google.state, { actor: 'participant-1' });
    seedDevice(google.state, 'organizer-1', 'phone', 'token-phone');
    const token = await idToken({ sub: 'participant-1' });
    const request = { recipientId: 'organizer-1', notificationId: 'booking_e1_p1_1' };

    await call(request, { token });
    const second = await call(request, { token });

    assert.deepEqual(second.body, { status: 'already_sent' });
    assert.equal(google.state.sent.length, 1);
  });

  test("refuse le push d'une notification dont l'appelant n'est pas l'auteur", async () => {
    seedNotice(google.state, { actor: 'participant-1' });
    seedDevice(google.state, 'organizer-1', 'phone', 'token-phone');

    const { status, body } = await call(
      { recipientId: 'organizer-1', notificationId: 'booking_e1_p1_1' },
      { token: await idToken({ sub: 'intruder' }) },
    );
    assert.equal(status, 403);
    assert.equal(body.error, 'not_the_actor');
    assert.equal(google.state.sent.length, 0);
  });

  test('refuse une notification trop ancienne ou inexistante', async () => {
    seedNotice(google.state, { actor: 'organizer-1', ageMs: MAX_AGE_MS + 1 });
    const old = await call({ recipientId: 'organizer-1', notificationId: 'booking_e1_p1_1' });
    assert.equal(old.status, 410);

    const missing = await call({ recipientId: 'organizer-1', notificationId: 'ghost' });
    assert.equal(missing.status, 404);
  });

  test('respecte la préférence du destinataire', async () => {
    seedNotice(google.state, { actor: 'participant-1' });
    seedDevice(google.state, 'organizer-1', 'phone', 'token-phone');
    google.state.docs.set('users/organizer-1/private/notifications', {
      fields: { bookingAlerts: { booleanValue: false } },
    });

    const { body } = await call(
      { recipientId: 'organizer-1', notificationId: 'booking_e1_p1_1' },
      { token: await idToken({ sub: 'participant-1' }) },
    );
    assert.deepEqual(body, { status: 'muted' });
    assert.equal(google.state.sent.length, 0);
  });

  test('supprime le document des appareils dont le jeton est mort', async () => {
    seedNotice(google.state, { actor: 'participant-1' });
    seedDevice(google.state, 'organizer-1', 'old-phone', 'token-dead');
    seedDevice(google.state, 'organizer-1', 'phone', 'token-phone');
    google.state.deadTokens.add('token-dead');

    const { body } = await call(
      { recipientId: 'organizer-1', notificationId: 'booking_e1_p1_1' },
      { token: await idToken({ sub: 'participant-1' }) },
    );
    assert.deepEqual(body, { status: 'sent', delivered: 1, pruned: 1 });
    assert.equal(google.state.docs.has('users/organizer-1/devices/old-phone'), false);
    assert.equal(google.state.docs.has('users/organizer-1/devices/phone'), true);
  });

  test('refuse les jetons forgés, expirés ou destinés à un autre projet', async () => {
    const request = { recipientId: 'organizer-1', notificationId: 'booking_e1_p1_1' };
    assert.equal((await call(request, { token: null })).status, 401);
    assert.equal((await call(request, { token: 'abc.def.ghi' })).status, 401);
    assert.equal((await call(request, { token: await idToken({ aud: 'eventhub-96d14' }) })).status, 401);
    assert.equal((await call(request, { token: await idToken({ exp: Math.floor(NOW / 1000) - 3600 }) })).status, 401);
    assert.equal((await call(request, { token: await idToken({}, { kid: 'unknown' }) })).status, 401);

    // Signature valide pour un autre contenu : charge utile échangée.
    const [header, , signature] = (await idToken()).split('.');
    const [, forgedPayload] = (await idToken({ sub: 'admin' })).split('.');
    assert.equal((await call(request, { token: `${header}.${forgedPayload}.${signature}` })).status, 401);
  });

  test('refuse un identifiant qui sortirait de la collection', async () => {
    const { status } = await call({ recipientId: 'organizer-1', notificationId: '../devices/phone' });
    assert.equal(status, 400);
  });

  test("n'ouvre le CORS qu'aux origines déclarées", async () => {
    seedNotice(google.state, { actor: 'organizer-1' });
    const allowed = await call({ recipientId: 'organizer-1', notificationId: 'booking_e1_p1_1' }, { origin: 'http://localhost:5050' });
    assert.equal(allowed.headers.get('access-control-allow-origin'), 'http://localhost:5050');
    const other = await call({ recipientId: 'organizer-1', notificationId: 'x' }, { origin: 'https://evil.example' });
    assert.equal(other.headers.get('access-control-allow-origin'), null);
  });

  test('réutilise le jeton OAuth et les clés publiques entre deux appels', async () => {
    seedNotice(google.state, { id: 'a', actor: 'organizer-1' });
    seedNotice(google.state, { id: 'b', actor: 'organizer-1' });
    await call({ recipientId: 'organizer-1', notificationId: 'a' });
    await call({ recipientId: 'organizer-1', notificationId: 'b' });
    assert.equal(google.state.calls.filter((c) => c.includes('oauth2')).length, 1);
    assert.equal(google.state.calls.filter((c) => c.includes('www.googleapis.com')).length, 1);
  });

  test('envoie le mail de bienvenue une seule fois, à l’adresse du jeton', async () => {
    google.state.docs.set('users/participant-1', { fields: { name: str('Soa Rakoto') } });
    const token = await idToken({ sub: 'participant-1', email: 'soa@example.com' });

    const first = await call({ email: 'victim@example.com' }, { token, path: '/v1/welcome' });
    const second = await call({}, { token, path: '/v1/welcome' });

    assert.deepEqual(first.body, { status: 'sent' });
    assert.deepEqual(second.body, { status: 'already_sent' });
    assert.equal(google.state.mails.length, 1);
    const [mail] = google.state.mails;
    // Le corps de la requête ne choisit jamais le destinataire.
    assert.deepEqual(mail.to, [{ email: 'soa@example.com', name: 'Soa Rakoto' }]);
    assert.equal(mail.subject, 'Bienvenue sur EventHub');
    assert.match(mail.textContent, /Félicitations/);
    assert.doesNotMatch(mail.textContent, /vérifi/i);
  });

  test('transmet un message à la boîte de l’entreprise, réponse vers l’utilisateur', async () => {
    const token = await idToken({ sub: 'participant-1', email: 'soa@example.com' });
    const { status } = await call(
      { subject: 'Remboursement', message: 'Bonjour, <b>mon billet</b> ne s’affiche plus.' },
      { token, path: '/v1/contact' },
    );
    assert.equal(status, 200);
    const [mail] = google.state.mails;
    assert.deepEqual(mail.to, [{ email: 'contact@eventhub.example', name: 'EventHub' }]);
    assert.equal(mail.replyTo.email, 'soa@example.com');
    assert.equal(mail.subject, '[Contact] Remboursement');
    // Le HTML saisi par l'utilisateur est neutralisé.
    assert.match(mail.htmlContent, /&lt;b&gt;mon billet&lt;\/b&gt;/);
  });

  test('limite le formulaire de contact à un message toutes les deux minutes', async () => {
    const token = await idToken({ sub: 'participant-1', email: 'soa@example.com' });
    const body = { subject: 'Question', message: 'Un message assez long pour passer.' };
    assert.equal((await call(body, { token, path: '/v1/contact' })).status, 200);
    assert.equal((await call(body, { token, path: '/v1/contact' })).status, 429);
    assert.ok(CONTACT_COOLDOWN_MS >= 60_000);
  });

  test('refuse un message vide ou une boîte d’entreprise non configurée', async () => {
    const token = await idToken({ sub: 'participant-1', email: 'soa@example.com' });
    assert.equal((await call({ subject: 'Hi', message: 'court' }, { token, path: '/v1/contact' })).status, 400);
    const unconfigured = await call(
      { subject: 'Question', message: 'Un message assez long pour passer.' },
      { token, path: '/v1/contact', envOverride: { COMPANY_EMAIL: '' } },
    );
    assert.equal(unconfigured.status, 503);
  });
});

describe('purgeReceipts', () => {
  test('supprime les reçus expirés et garde ceux qui protègent encore un envoi', async () => {
    const google = fakeGoogle();
    const accessToken = createAccessTokenProvider({ serviceAccount, fetchImpl: google.fetchImpl, now: () => NOW });
    const firestore = createFirestore({ projectId: PROJECT, accessToken, fetchImpl: google.fetchImpl });
    const receipt = (expiresAt) => ({ fields: { expiresAt: { timestampValue: new Date(expiresAt).toISOString() } } });
    google.state.docs.set('pushReceipts/u:old', receipt(NOW - 1));
    google.state.docs.set('pushReceipts/u:fresh', receipt(NOW + RECEIPT_LIFETIME_MS));

    assert.equal(await purgeReceipts({ firestore, now: () => NOW }), 1);
    assert.equal(google.state.docs.has('pushReceipts/u:old'), false);
    assert.equal(google.state.docs.has('pushReceipts/u:fresh'), true);
  });

  test('un reçu vit plus longtemps que la fenêtre de rejeu', () => {
    assert.ok(RECEIPT_LIFETIME_MS > MAX_AGE_MS);
  });
});

describe('escapeHtml', () => {
  test('neutralise les balises et les guillemets', () => {
    assert.equal(escapeHtml(`<a href="x">'</a>`), '&lt;a href=&quot;x&quot;&gt;&#39;&lt;/a&gt;');
  });
});

describe('buildMessage', () => {
  test("omet les champs nuls : FCM n'accepte que des chaînes dans data", () => {
    const message = buildMessage({
      token: 't',
      notificationId: 'staffRemoved_e1_u_1',
      notice: { type: 'staffRemoved', title: 'T', body: 'B', eventId: null, reservationId: null },
    });
    assert.deepEqual(message.data, { type: 'staffRemoved', notificationId: 'staffRemoved_e1_u_1' });
    assert.equal(message.webpush, undefined);
  });
});
