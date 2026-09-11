import { after, before, beforeEach, describe, it } from 'node:test';

import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import {
  deleteDoc,
  doc,
  getDoc,
  serverTimestamp,
  setDoc,
  updateDoc,
} from 'firebase/firestore';

import {
  asAdmin,
  asOrganizer,
  asParticipant,
  createTestEnv,
  eventData,
} from './helpers.js';

/**
 * Rules for the collections that exist server-side **before** the feature
 * that consumes them.
 *
 * Writing the rule after shipping the screen means shipping an open door for
 * the length of the gap; writing it first means the door is shut before
 * anyone knows it is there. The cost of that choice is exactly this file —
 * without it, those rules are unverified assertions. Each block names the
 * roadmap item it unblocks.
 */

let env;

before(async () => {
  env = await createTestEnv();
});

after(async () => {
  await env?.cleanup();
});

beforeEach(async () => {
  await env.clearFirestore();
});

async function seed(fn) {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await fn(ctx.firestore());
  });
}

const seedEvent = (id = 'e1', overrides = {}) =>
  seed((db) =>
    setDoc(doc(db, 'events', id), {
      ...eventData(overrides),
      createdAt: serverTimestamp(),
    }),
  );

// ===========================================================================
//  users/{uid}/devices — F-02 (push notifications)
// ===========================================================================

describe('devices (F-02 push)', () => {
  const device = (overrides = {}) => ({
    token: 'fcm-token-abcdefghijklmnop',
    platform: 'android',
    locale: 'fr',
    updatedAt: serverTimestamp(),
    ...overrides,
  });

  it('lets a user register their own device', async () => {
    const db = asParticipant(env, 'p1').firestore();
    await assertSucceeds(
      setDoc(doc(db, 'users', 'p1', 'devices', 'd1'), device()),
    );
  });

  it('refuses registering a device under another user', async () => {
    const db = asParticipant(env, 'p1').firestore();
    await assertFails(
      setDoc(doc(db, 'users', 'p2', 'devices', 'd1'), device()),
    );
  });

  it('refuses an unknown platform', async () => {
    const db = asParticipant(env, 'p1').firestore();
    await assertFails(
      setDoc(
        doc(db, 'users', 'p1', 'devices', 'd1'),
        device({ platform: 'symbian' }),
      ),
    );
  });

  it('refuses a suspiciously short token', async () => {
    const db = asParticipant(env, 'p1').firestore();
    await assertFails(
      setDoc(doc(db, 'users', 'p1', 'devices', 'd1'), device({ token: 'abc' })),
    );
  });

  it('refuses a client-supplied updatedAt', async () => {
    const db = asParticipant(env, 'p1').firestore();
    await assertFails(
      setDoc(
        doc(db, 'users', 'p1', 'devices', 'd1'),
        device({ updatedAt: new Date() }),
      ),
    );
  });

  it('refuses smuggling an extra field', async () => {
    const db = asParticipant(env, 'p1').firestore();
    await assertFails(
      setDoc(
        doc(db, 'users', 'p1', 'devices', 'd1'),
        device({ isAdmin: true }),
      ),
    );
  });

  it('keeps a device list private to its owner', async () => {
    await seed((db) =>
      setDoc(doc(db, 'users', 'p1', 'devices', 'd1'), {
        token: 'fcm-token-abcdefghijklmnop',
        platform: 'android',
      }),
    );

    await assertSucceeds(
      getDoc(
        doc(asParticipant(env, 'p1').firestore(), 'users', 'p1', 'devices', 'd1'),
      ),
    );
    await assertFails(
      getDoc(
        doc(asParticipant(env, 'p2').firestore(), 'users', 'p1', 'devices', 'd1'),
      ),
    );
  });

  it('lets the owner unregister a device', async () => {
    await seed((db) =>
      setDoc(doc(db, 'users', 'p1', 'devices', 'd1'), { token: 'x'.repeat(20) }),
    );
    const db = asParticipant(env, 'p1').firestore();
    await assertSucceeds(deleteDoc(doc(db, 'users', 'p1', 'devices', 'd1')));
  });
});

// ===========================================================================
//  users/{uid}/favorites — F-05 (wishlist)
// ===========================================================================

describe('favorites (F-05 wishlist)', () => {
  const favorite = (eventId = 'e1') => ({
    eventId,
    createdAt: serverTimestamp(),
  });

  it('stores a favourite at a document id equal to the event id', async () => {
    const db = asParticipant(env, 'p1').firestore();
    await assertSucceeds(
      setDoc(doc(db, 'users', 'p1', 'favorites', 'e1'), favorite('e1')),
    );
  });

  it('refuses a payload whose eventId contradicts the document id', async () => {
    const db = asParticipant(env, 'p1').firestore();
    await assertFails(
      setDoc(doc(db, 'users', 'p1', 'favorites', 'e1'), favorite('e2')),
    );
  });

  it('refuses starring on behalf of another user', async () => {
    const db = asParticipant(env, 'p1').firestore();
    await assertFails(
      setDoc(doc(db, 'users', 'p2', 'favorites', 'e1'), favorite('e1')),
    );
  });

  it('treats a favourite as immutable — unstar and star again instead', async () => {
    await seed((db) =>
      setDoc(doc(db, 'users', 'p1', 'favorites', 'e1'), {
        eventId: 'e1',
        createdAt: serverTimestamp(),
      }),
    );
    const db = asParticipant(env, 'p1').firestore();
    await assertFails(
      updateDoc(doc(db, 'users', 'p1', 'favorites', 'e1'), { eventId: 'e2' }),
    );
    await assertSucceeds(
      deleteDoc(doc(db, 'users', 'p1', 'favorites', 'e1')),
    );
  });

  it('keeps the wishlist private', async () => {
    await seed((db) =>
      setDoc(doc(db, 'users', 'p1', 'favorites', 'e1'), {
        eventId: 'e1',
        createdAt: serverTimestamp(),
      }),
    );
    await assertFails(
      getDoc(
        doc(
          asParticipant(env, 'p2').firestore(),
          'users',
          'p1',
          'favorites',
          'e1',
        ),
      ),
    );
  });
});

// ===========================================================================
//  users/{uid}/notifications — F-02
// ===========================================================================

describe('notifications (F-02)', () => {
  beforeEach(async () => {
    await seed((db) =>
      setDoc(doc(db, 'users', 'p1', 'notifications', 'n1'), {
        title: 'Votre événement commence demain',
        body: 'Flutter Meetup, 18 h.',
        createdAt: serverTimestamp(),
        readAt: null,
      }),
    );
  });

  it('refuses a client-forged notification — only the server writes these', async () => {
    const db = asParticipant(env, 'p1').firestore();
    await assertFails(
      setDoc(doc(db, 'users', 'p1', 'notifications', 'n2'), {
        title: 'Gagnez un iPhone',
        body: 'Cliquez ici',
        createdAt: serverTimestamp(),
      }),
    );
  });

  it('lets the recipient mark one as read', async () => {
    const db = asParticipant(env, 'p1').firestore();
    await assertSucceeds(
      updateDoc(doc(db, 'users', 'p1', 'notifications', 'n1'), {
        readAt: serverTimestamp(),
      }),
    );
  });

  it('refuses rewriting the content while marking it read', async () => {
    const db = asParticipant(env, 'p1').firestore();
    await assertFails(
      updateDoc(doc(db, 'users', 'p1', 'notifications', 'n1'), {
        readAt: serverTimestamp(),
        title: 'Autre chose',
      }),
    );
  });

  it('lets the recipient dismiss one', async () => {
    const db = asParticipant(env, 'p1').firestore();
    await assertSucceeds(
      deleteDoc(doc(db, 'users', 'p1', 'notifications', 'n1')),
    );
  });

  it('keeps notifications private to their recipient', async () => {
    await assertFails(
      getDoc(
        doc(
          asParticipant(env, 'p2').firestore(),
          'users',
          'p1',
          'notifications',
          'n1',
        ),
      ),
    );
  });
});

// ===========================================================================
//  events/{id}/waitlist — F-06
// ===========================================================================

describe('waitlist (F-06)', () => {
  const entry = (userId = 'p1') => ({
    userId,
    userName: 'Elie Rakoto',
    createdAt: serverTimestamp(),
  });

  beforeEach(async () => {
    await seedEvent('e1', { capacity: 10, availablePlaces: 0 });
  });

  it('lets a participant join the queue for themselves', async () => {
    const db = asParticipant(env, 'p1').firestore();
    await assertSucceeds(
      setDoc(doc(db, 'events', 'e1', 'waitlist', 'p1'), entry('p1')),
    );
  });

  it('refuses queueing somebody else', async () => {
    const db = asParticipant(env, 'p1').firestore();
    await assertFails(
      setDoc(doc(db, 'events', 'e1', 'waitlist', 'p2'), entry('p2')),
    );
  });

  it('refuses an organizer padding their own waiting list', async () => {
    const db = asOrganizer(env, 'o1').firestore();
    await assertFails(
      setDoc(doc(db, 'events', 'e1', 'waitlist', 'o1'), entry('o1')),
    );
  });

  it('lets the event organizer read the queue', async () => {
    await seed((db) =>
      setDoc(doc(db, 'events', 'e1', 'waitlist', 'p1'), {
        userId: 'p1',
        userName: 'Elie',
        createdAt: serverTimestamp(),
      }),
    );
    await assertSucceeds(
      getDoc(
        doc(asOrganizer(env, 'o1').firestore(), 'events', 'e1', 'waitlist', 'p1'),
      ),
    );
  });

  it('hides the queue from another organizer and from other participants', async () => {
    await seed((db) =>
      setDoc(doc(db, 'events', 'e1', 'waitlist', 'p1'), {
        userId: 'p1',
        userName: 'Elie',
        createdAt: serverTimestamp(),
      }),
    );
    await assertFails(
      getDoc(
        doc(asOrganizer(env, 'o2').firestore(), 'events', 'e1', 'waitlist', 'p1'),
      ),
    );
    await assertFails(
      getDoc(
        doc(
          asParticipant(env, 'p9').firestore(),
          'events',
          'e1',
          'waitlist',
          'p1',
        ),
      ),
    );
  });

  it('refuses editing a queue entry — position cannot be bought', async () => {
    await seed((db) =>
      setDoc(doc(db, 'events', 'e1', 'waitlist', 'p1'), {
        userId: 'p1',
        userName: 'Elie',
        createdAt: serverTimestamp(),
      }),
    );
    const db = asParticipant(env, 'p1').firestore();
    await assertFails(
      updateDoc(doc(db, 'events', 'e1', 'waitlist', 'p1'), {
        createdAt: serverTimestamp(),
      }),
    );
  });

  it('lets a participant leave the queue', async () => {
    await seed((db) =>
      setDoc(doc(db, 'events', 'e1', 'waitlist', 'p1'), {
        userId: 'p1',
        userName: 'Elie',
        createdAt: serverTimestamp(),
      }),
    );
    const db = asParticipant(env, 'p1').firestore();
    await assertSucceeds(deleteDoc(doc(db, 'events', 'e1', 'waitlist', 'p1')));
  });
});

// ===========================================================================
//  events/{id}/checkins — F-01 (door scanning)
// ===========================================================================

describe('checkins (F-01 door scanning)', () => {
  const checkin = (overrides = {}) => ({
    reservationId: 'e1_p1',
    scannedBy: 'o1',
    scannedAt: serverTimestamp(),
    ...overrides,
  });

  beforeEach(async () => {
    await seedEvent('e1');
  });

  it('lets the event organizer record a scan', async () => {
    const db = asOrganizer(env, 'o1').firestore();
    await assertSucceeds(
      setDoc(doc(db, 'events', 'e1', 'checkins', 'e1_p1'), checkin()),
    );
  });

  it('refuses a scan recorded by another organizer', async () => {
    const db = asOrganizer(env, 'o2').firestore();
    await assertFails(
      setDoc(
        doc(db, 'events', 'e1', 'checkins', 'e1_p1'),
        checkin({ scannedBy: 'o2' }),
      ),
    );
  });

  it('refuses a participant checking themselves in', async () => {
    const db = asParticipant(env, 'p1').firestore();
    await assertFails(
      setDoc(
        doc(db, 'events', 'e1', 'checkins', 'e1_p1'),
        checkin({ scannedBy: 'p1' }),
      ),
    );
  });

  it('refuses attributing a scan to somebody else', async () => {
    const db = asOrganizer(env, 'o1').firestore();
    await assertFails(
      setDoc(
        doc(db, 'events', 'e1', 'checkins', 'e1_p1'),
        checkin({ scannedBy: 'o2' }),
      ),
    );
  });

  it('is append-only: a scan is never edited nor erased', async () => {
    await seed((db) =>
      setDoc(doc(db, 'events', 'e1', 'checkins', 'e1_p1'), {
        reservationId: 'e1_p1',
        scannedBy: 'o1',
        scannedAt: serverTimestamp(),
      }),
    );
    const db = asOrganizer(env, 'o1').firestore();

    await assertFails(
      updateDoc(doc(db, 'events', 'e1', 'checkins', 'e1_p1'), {
        scannedBy: 'o2',
      }),
    );
    await assertFails(deleteDoc(doc(db, 'events', 'e1', 'checkins', 'e1_p1')));
  });

  it('is readable by the organizer, not by the attendee', async () => {
    await seed((db) =>
      setDoc(doc(db, 'events', 'e1', 'checkins', 'e1_p1'), {
        reservationId: 'e1_p1',
        scannedBy: 'o1',
        scannedAt: serverTimestamp(),
      }),
    );
    await assertSucceeds(
      getDoc(
        doc(asOrganizer(env, 'o1').firestore(), 'events', 'e1', 'checkins', 'e1_p1'),
      ),
    );
    await assertFails(
      getDoc(
        doc(
          asParticipant(env, 'p1').firestore(),
          'events',
          'e1',
          'checkins',
          'e1_p1',
        ),
      ),
    );
  });
});

// ===========================================================================
//  reports — F-19 (moderation)
// ===========================================================================

describe('reports (F-19 moderation)', () => {
  const report = (overrides = {}) => ({
    targetType: 'event',
    targetId: 'e1',
    reason: 'contenu-trompeur',
    details: 'Les informations pratiques ne correspondent pas.',
    reporterId: 'p1',
    createdAt: serverTimestamp(),
    ...overrides,
  });

  it('lets any signed-in user file a report', async () => {
    const db = asParticipant(env, 'p1').firestore();
    await assertSucceeds(setDoc(doc(db, 'reports', 'r1'), report()));
  });

  it('refuses a report filed under somebody else’s name', async () => {
    const db = asParticipant(env, 'p1').firestore();
    await assertFails(
      setDoc(doc(db, 'reports', 'r1'), report({ reporterId: 'p2' })),
    );
  });

  it('refuses an unknown target type', async () => {
    const db = asParticipant(env, 'p1').firestore();
    await assertFails(
      setDoc(doc(db, 'reports', 'r1'), report({ targetType: 'organisation' })),
    );
  });

  it('refuses an oversized narrative', async () => {
    const db = asParticipant(env, 'p1').firestore();
    await assertFails(
      setDoc(doc(db, 'reports', 'r1'), report({ details: 'x'.repeat(2001) })),
    );
  });

  it('is write-only for the client: a reporter cannot read reports back', async () => {
    await seed((db) => setDoc(doc(db, 'reports', 'r1'), report()));

    // Not even their own — otherwise a reported organizer could confirm who
    // flagged them by filing a report and probing the collection.
    await assertFails(
      getDoc(doc(asParticipant(env, 'p1').firestore(), 'reports', 'r1')),
    );
    await assertFails(
      getDoc(doc(asOrganizer(env, 'o1').firestore(), 'reports', 'r1')),
    );
  });

  it('is readable and resolvable by an admin only', async () => {
    await seed((db) => setDoc(doc(db, 'reports', 'r1'), report()));
    const db = asAdmin(env).firestore();

    await assertSucceeds(getDoc(doc(db, 'reports', 'r1')));
    await assertSucceeds(
      updateDoc(doc(db, 'reports', 'r1'), { status: 'resolved' }),
    );
  });

  it('refuses a non-admin resolving a report', async () => {
    await seed((db) => setDoc(doc(db, 'reports', 'r1'), report()));
    const db = asOrganizer(env, 'o1').firestore();
    await assertFails(
      updateDoc(doc(db, 'reports', 'r1'), { status: 'resolved' }),
    );
  });
});
