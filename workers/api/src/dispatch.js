// Cœur du Worker : décider si une notification Firestore mérite un push, puis
// l'envoyer à chaque appareil de son destinataire.
//
// Le Worker ne crée jamais de notification. Il ne fait que relayer vers FCM
// un document que les règles Firestore ont déjà accepté : c'est ce qui rend
// l'appel sûr alors qu'il vient du téléphone. Un client forgé ne peut donc
// pas pousser un texte arbitraire vers un inconnu — il lui faudrait d'abord
// écrire la notification, ce que les règles réservent aux faits prouvés
// (réservation confirmée, invitation, décision de modération…).

import { HttpError } from './google.js';

/// Au-delà, l'appel n'est plus la suite immédiate de l'écriture : on refuse,
/// pour qu'une notification vieille d'un mois ne ressorte pas en push.
export const MAX_AGE_MS = 10 * 60 * 1000;

/// Même plafond de 400 caractères que les règles Firestore ; `/` est exclu
/// pour qu'aucun identifiant ne fasse sortir le chemin de sa collection.
const ID = /^[A-Za-z0-9_\-:.]{1,400}$/;

/// Quelle préférence de `users/{uid}/private/notifications` coupe quel type.
/// Les types absents de cette table (modération, équipe) ne se désactivent
/// pas : une suspension de compte doit être sue.
export const PREFERENCE_FOR_TYPE = {
  booking: 'bookingAlerts',
  cancellation: 'bookingAlerts',
  waitlist: 'eventReminders',
  reminder: 'eventReminders',
  newEvent: 'followedOrganizers',
};

/// Canal Android créé par l'app (`LocalNotificationDataSource`). Un push qui
/// en nomme un autre tomberait dans « Divers », à l'importance par défaut.
const ANDROID_CHANNEL = 'eventhub_default';

/// Durée de vie d'un reçu d'envoi. Il ne sert qu'à bloquer un second envoi
/// tant que la notification passe encore le contrôle d'âge (MAX_AGE_MS) ;
/// au-delà, ce contrôle suffit et le reçu peut disparaître. Les politiques
/// TTL de Firestore exigeant un compte de facturation, c'est la tâche
/// planifiée du Worker (`purgeReceipts`) qui les supprime.
export const RECEIPT_LIFETIME_MS = MAX_AGE_MS + 5 * 60 * 1000;

// ------------------------------------------------------------- Firestore

const stringOf = (field) => field?.stringValue ?? null;

export function createFirestore({ projectId, accessToken, fetchImpl = fetch }) {
  const base = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents`;

  async function call(path, init = {}) {
    // `:runQuery` et `:commit` sont des méthodes de la base, sans « / ».
    const url = path.startsWith(':') ? `${base}${path}` : `${base}/${path}`;
    const response = await fetchImpl(url, {
      ...init,
      headers: {
        authorization: `Bearer ${await accessToken()}`,
        'content-type': 'application/json',
        ...init.headers,
      },
    });
    return response;
  }

  return {
    async get(path) {
      const response = await call(path);
      if (response.status === 404) return null;
      if (!response.ok) throw new HttpError(503, 'firestore_unavailable');
      return response.json();
    },

    async list(path, pageSize) {
      const response = await call(`${path}?pageSize=${pageSize}`);
      if (!response.ok) throw new HttpError(503, 'firestore_unavailable');
      const { documents = [] } = await response.json();
      return documents;
    },

    /// Création qui échoue si le document existe : c'est ce qui rend l'envoi
    /// idempotent même si deux appels arrivent en même temps sur deux
    /// isolats Cloudflare différents.
    async createOnce(collection, id, fields) {
      const response = await call(`${collection}?documentId=${encodeURIComponent(id)}`, {
        method: 'POST',
        body: JSON.stringify({ fields }),
      });
      if (response.status === 409) return false;
      if (!response.ok) throw new HttpError(503, 'firestore_unavailable');
      return true;
    },

    /// Chemins relatifs des reçus expirés, les plus anciens d'abord.
    async expiredReceipts(before, limit) {
      const response = await call(':runQuery', {
        method: 'POST',
        body: JSON.stringify({
          structuredQuery: {
            from: [{ collectionId: 'pushReceipts' }],
            where: {
              fieldFilter: {
                field: { fieldPath: 'expiresAt' },
                op: 'LESS_THAN',
                value: { timestampValue: new Date(before).toISOString() },
              },
            },
            orderBy: [{ field: { fieldPath: 'expiresAt' }, direction: 'ASCENDING' }],
            limit,
          },
        }),
      });
      if (!response.ok) throw new HttpError(503, 'firestore_unavailable');
      const rows = await response.json();
      return rows.filter((row) => row.document).map((row) => row.document.name);
    },

    /// Suppression groupée en un seul appel (`:commit`), pour rester loin du
    /// plafond de sous-requêtes d'une invocation gratuite.
    async removeAll(names) {
      if (names.length === 0) return;
      const response = await call(':commit', {
        method: 'POST',
        body: JSON.stringify({ writes: names.map((name) => ({ delete: name })) }),
      });
      if (!response.ok) throw new HttpError(503, 'firestore_unavailable');
    },

    /// Écrit (ou remplace) les champs donnés d'un document.
    async upsert(path, fields) {
      const mask = Object.keys(fields).map((f) => `updateMask.fieldPaths=${encodeURIComponent(f)}`).join('&');
      const response = await call(`${path}?${mask}`, { method: 'PATCH', body: JSON.stringify({ fields }) });
      if (!response.ok) throw new HttpError(503, 'firestore_unavailable');
    },

    async remove(path) {
      const response = await call(path, { method: 'DELETE' });
      if (!response.ok && response.status !== 404) {
        console.warn(`Could not prune ${path} (${response.status})`);
      }
    },
  };
}

// -------------------------------------------------------------------- FCM

/// `UNREGISTERED` : l'app a été désinstallée ou le jeton renouvelé.
/// `INVALID_ARGUMENT` sur le jeton : il n'a jamais été valide. Dans les deux
/// cas, le document de l'appareil ne servira plus jamais.
function isDeadToken(status, body) {
  const codes = (body?.error?.details ?? []).map((detail) => detail.errorCode);
  return status === 404 || codes.includes('UNREGISTERED') ||
    (status === 400 && codes.includes('INVALID_ARGUMENT'));
}

export function createMessenger({ projectId, accessToken, fetchImpl = fetch }) {
  const url = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;

  return async function send(message) {
    const response = await fetchImpl(url, {
      method: 'POST',
      headers: {
        authorization: `Bearer ${await accessToken()}`,
        'content-type': 'application/json',
      },
      body: JSON.stringify({ message }),
    });
    if (response.ok) return 'delivered';
    const body = await response.json().catch(() => null);
    if (isDeadToken(response.status, body)) return 'dead';
    console.warn(`FCM refused a message (${response.status})`);
    return 'failed';
  };
}

/// Le message FCM d'une notification.
///
/// Un bloc `notification` pour que le système l'affiche app fermée ; les
/// mêmes clés en `data` que le document, parce que c'est ce que lit
/// `NotificationRoute.locationFor` pour ouvrir le bon écran au toucher. FCM
/// n'accepte que des chaînes dans `data`, d'où l'omission des champs nuls.
export function buildMessage({ token, notificationId, notice, appOrigin }) {
  const data = { type: notice.type, notificationId };
  if (notice.eventId) data.eventId = notice.eventId;
  if (notice.reservationId) data.reservationId = notice.reservationId;

  return {
    token,
    notification: { title: notice.title, body: notice.body },
    data,
    android: {
      priority: 'HIGH',
      // `tag` : un second envoi de la même notification remplace la première
      // au lieu de s'empiler — filet de sécurité en plus du reçu.
      notification: { channel_id: ANDROID_CHANNEL, tag: notificationId },
    },
    apns: { payload: { aps: { sound: 'default' } } },
    ...(appOrigin ? { webpush: { fcm_options: { link: appOrigin } } } : {}),
  };
}

// --------------------------------------------------------------- dispatch

export function validateRequest(body) {
  const recipientId = body?.recipientId;
  const notificationId = body?.notificationId;
  if (typeof recipientId !== 'string' || !ID.test(recipientId) || recipientId.startsWith('.')) {
    throw new HttpError(400, 'bad_recipient');
  }
  if (typeof notificationId !== 'string' || !ID.test(notificationId) || notificationId.startsWith('.')) {
    throw new HttpError(400, 'bad_notification');
  }
  return { recipientId, notificationId };
}

/// Envoie le push d'une notification déjà écrite.
///
/// Ordre des contrôles, du moins coûteux au plus coûteux, et chacun avec sa
/// raison :
///  1. la notification existe (sinon rien à relayer) ;
///  2. l'appelant en est l'auteur (`actorId`) — personne ne déclenche le push
///     d'un fait qu'il n'a pas provoqué ;
///  3. elle est récente (MAX_AGE_MS) — pas de rejeu d'anciennes notifications ;
///  4. le reçu est créé une seule fois — pas de double envoi ;
///  5. le destinataire n'a pas coupé ce type dans ses préférences ;
///  6. envoi à chaque appareil, et nettoyage des jetons morts.
export async function dispatch({ callerId, request, firestore, send, now = () => Date.now(), appOrigin }) {
  const { recipientId, notificationId } = request;
  const path = `users/${recipientId}/notifications/${notificationId}`;

  const doc = await firestore.get(path);
  if (!doc) throw new HttpError(404, 'notification_not_found');

  const fields = doc.fields ?? {};
  const notice = {
    type: stringOf(fields.type),
    title: stringOf(fields.title),
    body: stringOf(fields.body),
    eventId: stringOf(fields.eventId),
    reservationId: stringOf(fields.reservationId),
    actorId: stringOf(fields.actorId),
  };
  if (notice.actorId !== callerId) throw new HttpError(403, 'not_the_actor');
  if (!notice.type || !notice.title || !notice.body) throw new HttpError(422, 'incomplete_notification');

  const createdAt = Date.parse(doc.createTime);
  if (!Number.isFinite(createdAt) || now() - createdAt > MAX_AGE_MS) {
    throw new HttpError(410, 'notification_too_old');
  }

  const first = await firestore.createOnce('pushReceipts', `${recipientId}:${notificationId}`, {
    recipientId: { stringValue: recipientId },
    notificationId: { stringValue: notificationId },
    actorId: { stringValue: callerId },
    sentAt: { timestampValue: new Date(now()).toISOString() },
    expiresAt: { timestampValue: new Date(now() + RECEIPT_LIFETIME_MS).toISOString() },
  });
  if (!first) return { status: 'already_sent' };

  const preference = PREFERENCE_FOR_TYPE[notice.type];
  if (preference) {
    const prefs = await firestore.get(`users/${recipientId}/private/notifications`);
    // Absent vaut `true` : c'est la valeur par défaut côté app.
    if (prefs?.fields?.[preference]?.booleanValue === false) return { status: 'muted' };
  }

  // Vingt appareils par compte au plus : le plan gratuit limite les
  // sous-requêtes d'une invocation, et personne n'a vingt téléphones.
  const devices = await firestore.list(`users/${recipientId}/devices`, 20);
  let delivered = 0;
  let pruned = 0;
  for (const device of devices) {
    const token = stringOf(device.fields?.token);
    if (!token) continue;
    const outcome = await send(buildMessage({ token, notificationId, notice, appOrigin }));
    if (outcome === 'delivered') delivered++;
    if (outcome === 'dead') {
      pruned++;
      // `name` est le chemin complet : on ne garde que la partie relative.
      await firestore.remove(device.name.split('/documents/')[1]);
    }
  }
  return { status: devices.length ? 'sent' : 'no_device', delivered, pruned };
}

/// Tâche planifiée : supprime les reçus d'envoi expirés, par lots de 400
/// (une écriture groupée Firestore en accepte 500). Trois lots au plus par
/// passage : au rythme horaire, cela couvre 28 000 push par jour, bien
/// au-delà de ce que produit EventHub.
export async function purgeReceipts({ firestore, now = () => Date.now() }) {
  let removed = 0;
  for (let round = 0; round < 3; round++) {
    const names = await firestore.expiredReceipts(now(), 400);
    await firestore.removeAll(names);
    removed += names.length;
    if (names.length < 400) break;
  }
  return removed;
}
