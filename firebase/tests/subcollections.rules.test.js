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

  it('refuses joining the queue of an event that still has seats', async () => {
    await seedEvent('e2', { capacity: 10, availablePlaces: 3 });
    const db = asParticipant(env, 'p1').firestore();
    await assertFails(
      setDoc(doc(db, 'events', 'e2', 'waitlist', 'p1'), entry('p1')),
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
    reason: 'misleading',
    details: 'Les informations pratiques ne correspondent pas.',
    reporterId: 'p1',
    createdAt: serverTimestamp(),
    ...overrides,
  });
  const idOf = (r) => `${r.targetType}_${r.targetId}_${r.reporterId}`;
  const file = (db, r) => setDoc(doc(db, 'reports', idOf(r)), r);

  it('lets any signed-in user file a report', async () => {
    const db = asParticipant(env, 'p1').firestore();
    await assertSucceeds(file(db, report()));
  });

  it('refuses a report filed under somebody else’s name', async () => {
    const db = asParticipant(env, 'p1').firestore();
    const r = report({ reporterId: 'p2' });
    await assertFails(file(db, r));
  });

  it('refuses a report whose id is not target + reporter (one vote per account)', async () => {
    const db = asParticipant(env, 'p1').firestore();
    await assertFails(setDoc(doc(db, 'reports', 'r1'), report()));
    await assertFails(
      setDoc(doc(db, 'reports', 'event_e1_p1_bis'), report()),
    );
  });

  it('refuses reporting the same target twice from one account', async () => {
    await seed((db) => setDoc(doc(db, 'reports', 'event_e1_p1'), report()));
    const db = asParticipant(env, 'p1').firestore();
    await assertFails(file(db, report({ reason: 'spam' })));
  });

  it('refuses an unknown target type or reason', async () => {
    const db = asParticipant(env, 'p1').firestore();
    await assertFails(file(db, report({ targetType: 'organisation' })));
    await assertFails(file(db, report({ reason: 'je-n-aime-pas' })));
  });

  it('refuses reporting oneself or one’s own review', async () => {
    const db = asParticipant(env, 'p1').firestore();
    await assertFails(file(db, report({ targetType: 'user', targetId: 'p1' })));
    await assertFails(
      file(db, report({ targetType: 'review', targetId: 'e1_p1' })),
    );
    await assertSucceeds(
      file(db, report({ targetType: 'review', targetId: 'e1_p2' })),
    );
  });

  it('refuses an oversized narrative', async () => {
    const db = asParticipant(env, 'p1').firestore();
    await assertFails(file(db, report({ details: 'x'.repeat(2001) })));
  });

  it('is write-only for the client: a reporter cannot read reports back', async () => {
    await seed((db) => setDoc(doc(db, 'reports', 'event_e1_p1'), report()));

    // Not even their own — otherwise a reported organizer could confirm who
    // flagged them by filing a report and probing the collection.
    await assertFails(
      getDoc(doc(asParticipant(env, 'p1').firestore(), 'reports', 'event_e1_p1')),
    );
    await assertFails(
      getDoc(doc(asOrganizer(env, 'o1').firestore(), 'reports', 'event_e1_p1')),
    );
  });

  it('is readable and resolvable by an admin only', async () => {
    await seed((db) => setDoc(doc(db, 'reports', 'event_e1_p1'), report()));
    const db = asAdmin(env).firestore();

    await assertSucceeds(getDoc(doc(db, 'reports', 'event_e1_p1')));
    await assertSucceeds(
      updateDoc(doc(db, 'reports', 'event_e1_p1'), { status: 'resolved' }),
    );
  });

  it('refuses a non-admin resolving a report', async () => {
    await seed((db) => setDoc(doc(db, 'reports', 'event_e1_p1'), report()));
    const db = asOrganizer(env, 'o1').firestore();
    await assertFails(
      updateDoc(doc(db, 'reports', 'event_e1_p1'), { status: 'resolved' }),
    );
  });
});

// ===========================================================================
//  users/{uid}/following + organizers/{id} — F-10 (public organizer profile)
// ===========================================================================

describe('following (F-10)', () => {
  const follow = (organizerId = 'o1') => ({
    organizerId,
    createdAt: serverTimestamp(),
  });

  it('lets a user follow an organizer under their own account', async () => {
    const db = asParticipant(env, 'p1').firestore();
    await assertSucceeds(
      setDoc(doc(db, 'users', 'p1', 'following', 'o1'), follow('o1')),
    );
  });

  it('refuses following on behalf of someone else', async () => {
    const db = asParticipant(env, 'p1').firestore();
    await assertFails(
      setDoc(doc(db, 'users', 'p2', 'following', 'o1'), follow('o1')),
    );
  });

  it('refuses an id that contradicts the payload, and following oneself', async () => {
    const db = asOrganizer(env, 'o1').firestore();
    await assertFails(
      setDoc(doc(db, 'users', 'o1', 'following', 'o2'), follow('o3')),
    );
    await assertFails(
      setDoc(doc(db, 'users', 'o1', 'following', 'o1'), follow('o1')),
    );
  });

  it('keeps the list private and immutable; unfollow is a delete', async () => {
    await seed((db) =>
      setDoc(doc(db, 'users', 'p1', 'following', 'o1'), {
        organizerId: 'o1',
        createdAt: serverTimestamp(),
      }),
    );
    await assertFails(
      getDoc(doc(asOrganizer(env, 'o1').firestore(), 'users', 'p1', 'following', 'o1')),
    );
    const db = asParticipant(env, 'p1').firestore();
    await assertFails(
      updateDoc(doc(db, 'users', 'p1', 'following', 'o1'), { organizerId: 'o2' }),
    );
    await assertSucceeds(deleteDoc(doc(db, 'users', 'p1', 'following', 'o1')));
  });
});

describe('organizers (F-10 public profile)', () => {
  beforeEach(async () => {
    await seed(async (db) => {
      await setDoc(doc(db, 'organizers', 'o1'), {
        name: 'Hasina',
        bio: 'Meetups Flutter à Tana.',
        followerCount: 12,
      });
      await setDoc(doc(db, 'organizers', 'o1', 'followers', 'p1'), {
        userId: 'p1',
      });
    });
  });

  it('is readable by any signed-in user', async () => {
    await assertSucceeds(
      getDoc(doc(asParticipant(env, 'p9').firestore(), 'organizers', 'o1')),
    );
  });

  it('is never writable from a client, not even by the organizer', async () => {
    const db = asOrganizer(env, 'o1').firestore();
    await assertFails(updateDoc(doc(db, 'organizers', 'o1'), { followerCount: 9999 }));
    await assertFails(setDoc(doc(db, 'organizers', 'o2'), { name: 'Faux' }));
  });

  it('hides who follows whom, from the organizer too', async () => {
    await assertFails(
      getDoc(doc(asOrganizer(env, 'o1').firestore(), 'organizers', 'o1', 'followers', 'p1')),
    );
  });
});

// ===========================================================================
//  aggregates — F-07 (social proof)
// ===========================================================================

describe('moderationQueue (F-19)', () => {
  beforeEach(async () => {
    await seed((db) =>
      setDoc(doc(db, 'moderationQueue', 'review_e1_p2'), {
        targetType: 'review',
        targetId: 'e1_p2',
        reportCount: 3,
        status: 'open',
      }),
    );
  });

  it('is readable by an admin only', async () => {
    await assertSucceeds(
      getDoc(doc(asAdmin(env).firestore(), 'moderationQueue', 'review_e1_p2')),
    );
    await assertFails(
      getDoc(doc(asOrganizer(env, 'o1').firestore(), 'moderationQueue', 'review_e1_p2')),
    );
  });

  it('keeps the decision history and the admin list admin-only and server-written', async () => {
    await seed(async (db) => {
      await setDoc(doc(db, 'moderationQueue', 'review_e1_p2', 'decisions', 'd1'), {
        action: 'hide',
      });
      await setDoc(doc(db, 'admins', 'admin1'), { email: 'admin1@example.com' });
    });
    const admin = asAdmin(env).firestore();
    await assertSucceeds(
      getDoc(doc(admin, 'moderationQueue', 'review_e1_p2', 'decisions', 'd1')),
    );
    await assertSucceeds(getDoc(doc(admin, 'admins', 'admin1')));
    await assertFails(setDoc(doc(admin, 'admins', 'o1'), { email: 'x' }));
    await assertFails(
      getDoc(doc(asOrganizer(env, 'o1').firestore(), 'admins', 'admin1')),
    );
    await assertFails(
      getDoc(
        doc(asParticipant(env, 'p1').firestore(), 'moderationQueue', 'review_e1_p2', 'decisions', 'd1'),
      ),
    );
  });

  it('is written by functions only, admins included', async () => {
    await assertFails(
      updateDoc(doc(asAdmin(env).firestore(), 'moderationQueue', 'review_e1_p2'), {
        status: 'dismissed',
      }),
    );
  });
});

describe('aggregates (F-07 social proof)', () => {
  it('is readable when signed in, writable by nobody', async () => {
    await seed((db) =>
      setDoc(doc(db, 'aggregates', 'event_e1'), {
        eventId: 'e1',
        recentAttendees: [{ key: 'abc', name: 'Hery R.' }],
      }),
    );
    const db = asParticipant(env, 'p1').firestore();
    await assertSucceeds(getDoc(doc(db, 'aggregates', 'event_e1')));
    await assertFails(
      setDoc(doc(db, 'aggregates', 'event_e1'), { recentAttendees: [] }),
    );
  });
});
