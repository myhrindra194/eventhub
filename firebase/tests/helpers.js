import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

import { initializeTestEnvironment } from '@firebase/rules-unit-testing';
import { Timestamp } from 'firebase/firestore';

const here = dirname(fileURLToPath(import.meta.url));

/**
 * A `demo-` prefixed project id tells the Firebase SDK that no real project
 * exists behind it, so the emulators never ask for credentials.
 */
export const PROJECT_ID = 'demo-eventhub';

/**
 * Boots a test environment wired to the running emulators.
 *
 * Host and port come from the environment variables that
 * `firebase emulators:exec` injects, with the values of `firebase.json` as a
 * fallback so the suite also runs against a manually started emulator.
 */
export async function createTestEnv() {
  const [fsHost, fsPort] = (
    process.env.FIRESTORE_EMULATOR_HOST ?? '127.0.0.1:8080'
  ).split(':');
  const [stHost, stPort] = (
    process.env.FIREBASE_STORAGE_EMULATOR_HOST ?? '127.0.0.1:9199'
  ).split(':');

  return initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: readFileSync(join(here, '..', 'firestore.rules'), 'utf8'),
      host: fsHost,
      port: Number(fsPort),
    },
    storage: {
      rules: readFileSync(join(here, '..', 'storage.rules'), 'utf8'),
      host: stHost,
      port: Number(stPort),
    },
  });
}

// ---------------------------------------------------------------- identities

/**
 * An authenticated context carrying custom claims.
 *
 * Passing `role` as a claim exercises the **production** path of `role()`:
 * no document read, nothing a client could tamper with. The document-fallback
 * path is covered explicitly by its own test.
 */
export function asParticipant(env, uid = 'p1', extra = {}) {
  return env.authenticatedContext(uid, {
    email: `${uid}@example.com`,
    email_verified: true,
    role: 'participant',
    ...extra,
  });
}

export function asOrganizer(env, uid = 'o1', extra = {}) {
  return env.authenticatedContext(uid, {
    email: `${uid}@example.com`,
    email_verified: true,
    role: 'organizer',
    ...extra,
  });
}

export function asAdmin(env, uid = 'admin1') {
  return env.authenticatedContext(uid, {
    email: `${uid}@example.com`,
    email_verified: true,
    admin: true,
  });
}

/** Signed in, but with no role claim at all — exercises the fallback branch. */
export function asClaimless(env, uid) {
  return env.authenticatedContext(uid, {
    email: `${uid}@example.com`,
    email_verified: true,
  });
}

export function asAnonymous(env) {
  return env.unauthenticatedContext();
}

// ------------------------------------------------------------------ fixtures

/**
 * Fixture clock, frozen when the module loads.
 *
 * It has to be: `matchesEvent()` compares the reservation's denormalised
 * `eventStartsAt` against the event's `startsAt` for **exact** equality — that
 * is the whole point of the rule. Recomputing `Date.now()` for each fixture
 * makes the two differ by a few milliseconds and the rule rightly refuses the
 * write, which would look like a rules bug and is in fact a test bug.
 */
const CLOCK = Date.now();

export const inDays = (days) =>
  Timestamp.fromMillis(CLOCK + days * 86_400_000);

export const daysAgo = (days) => inDays(-days);

/**
 * A valid event payload. `createdAt` is intentionally absent: a *create* must
 * send `serverTimestamp()`, and each test decides that explicitly.
 */
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
    organizerName: 'Hasina',
    ...overrides,
  };
}

export function userData(overrides = {}) {
  return {
    name: 'Elie Rakoto',
    email: 'p1@example.com',
    role: 'participant',
    ...overrides,
  };
}

export function reservationData(overrides = {}) {
  return {
    eventId: 'e1',
    userId: 'p1',
    organizerId: 'o1',
    userName: 'Elie Rakoto',
    userEmail: 'p1@example.com',
    eventTitle: 'Flutter Meetup Antananarivo',
    eventStartsAt: inDays(7),
    eventLocation: 'Antananarivo',
    status: 'confirmed',
    reservedAt: Timestamp.now(),
    ...overrides,
  };
}

/** Deterministic reservation id — the anti-duplicate guarantee. */
export const reservationId = (eventId, userId) => `${eventId}_${userId}`;
