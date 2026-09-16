import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

import { assertFails, assertSucceeds, initializeTestEnvironment } from '@firebase/rules-unit-testing';
import { Timestamp, doc, serverTimestamp, setDoc } from 'firebase/firestore';

const here = dirname(fileURLToPath(import.meta.url));

/** Projet `demo-` : l’émulateur ne demande jamais d’identifiants. */
export const PROJECT_ID = 'demo-eventhub';

export { assertFails, assertSucceeds };

export async function createTestEnv() {
  const [host, port] = (process.env.FIRESTORE_EMULATOR_HOST ?? '127.0.0.1:8080').split(':');
  return initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: readFileSync(join(here, '..', 'firestore.rules'), 'utf8'),
      host,
      port: Number(port),
    },
  });
}

// ----------------------------------------------------------------- identités

/** Une personne authentifiée. Le rôle vit dans `users/{uid}`, via [seedUser]. */
export function as(env, uid, { verified = true } = {}) {
  return env.authenticatedContext(uid, { email: `${uid}@example.com`, email_verified: verified });
}

export function asAnonymous(env) {
  return env.unauthenticatedContext();
}

/** Écrit des documents en contournant les règles (jeux d’essai). */
export async function seed(env, writes) {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    for (const [path, data] of writes) {
      await setDoc(doc(db, path), data);
    }
  });
}

export async function seedUser(env, uid, { role = 'participant', name = `Name ${uid}`, suspended, fields = {} } = {}) {
  const writes = [[`users/${uid}`, {
    name, email: `${uid}@example.com`, role, createdAt: Timestamp.now(), ...(suspended ? { suspended: true } : {}), ...fields,
  }]];
  if (role === 'organizer') {
    writes.push([`organizers/${uid}`, {
      name, bio: '', memberSince: Timestamp.now(), followerCount: 0, eventCount: 0, ratingSum: 0, ratingCount: 0,
    }]);
  }
  await seed(env, writes);
}

export async function seedAdmin(env, uid) {
  await seedUser(env, uid);
  await seed(env, [[`admins/${uid}`, { grantedAt: Timestamp.now() }]]);
}

// -------------------------------------------------------------- jeux d’essai

const CLOCK = Date.now();
export const inDays = (days) => Timestamp.fromMillis(CLOCK + days * 86_400_000);
export const daysAgo = (days) => inDays(-days);

export function eventData(overrides = {}) {
  return {
    title: 'Flutter Meetup Antananarivo',
    description: 'Une soirée autour de Flutter et Firebase.',
    category: 'meetup',
    startsAt: inDays(7),
    location: 'Antananarivo',
    capacity: 10,
    availablePlaces: 10,
    organizerId: 'o1',
    organizerName: 'Name o1',
    staffIds: [],
    createdAt: Timestamp.now(),
    ...overrides,
  };
}

export function reservationData(overrides = {}) {
  return {
    eventId: 'e1',
    userId: 'p1',
    organizerId: 'o1',
    userName: 'Name p1',
    userEmail: 'p1@example.com',
    eventTitle: 'Flutter Meetup Antananarivo',
    eventStartsAt: inDays(7),
    eventLocation: 'Antananarivo',
    status: 'confirmed',
    reservedAt: Timestamp.now(),
    cancelledAt: null,
    pricePaid: 0,
    ...overrides,
  };
}

export const reservationId = (eventId, userId) => `${eventId}_${userId}`;

/** La clé de participant attendue par les règles : sha256(uid), hexa minuscule. */
export const attendeeKey = (uid) => createHash('sha256').update(uid).digest('hex');

export { serverTimestamp, assert };
