import assert from 'node:assert/strict';
import { after, before, beforeEach, describe, it } from 'node:test';

import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  limit,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
} from 'firebase/firestore';

import {
  asAdmin,
  asAnonymous,
  asClaimless,
  asOrganizer,
  asParticipant,
  createTestEnv,
  daysAgo,
  eventData,
  inDays,
  reservationData,
  reservationId,
  userData,
} from './helpers.js';

/**
 * Firestore security-rules suite.
 *
 * Every test drives the emulator through the *client* SDK, exactly as a
 * hostile client would: the payloads here are hand-crafted, not produced by
 * the Flutter repositories. That is the whole point — these rules are the
 * only control that actually runs, so they are tested in isolation from the
 * application that is supposed to respect them.
 *
 * The seven cases flagged as priorities in `docs/SECURITY.md` are tagged
 * `[P-n]` in their titles.
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

/** Writes fixtures with the rules turned off. */
async function seed(fn) {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await fn(ctx.firestore());
  });
}

async function seedEvent(id = 'e1', overrides = {}) {
  await seed((db) =>
    setDoc(doc(db, 'events', id), {
      ...eventData(overrides),
      createdAt: serverTimestamp(),
    }),
  );
}

async function seedReservation(id, overrides = {}) {
  await seed((db) =>
    setDoc(doc(db, 'reservations', id), reservationData(overrides)),
  );
}

// ===========================================================================
//  users
// ===========================================================================

describe('users', () => {
  it('lets a signed-in user create their own profile', async () => {
    const db = asParticipant(env).firestore();
    await assertSucceeds(
      setDoc(doc(db, 'users', 'p1'), {
        ...userData(),
        createdAt: serverTimestamp(),
      }),
    );
  });

  it('refuses a profile created for somebody else', async () => {
    const db = asParticipant(env, 'p1').firestore();
    await assertFails(
      setDoc(doc(db, 'users', 'p2'), {
        ...userData({ email: 'p2@example.com' }),
        createdAt: serverTimestamp(),
      }),
    );
  });

  it('refuses a client-supplied createdAt', async () => {
    const db = asParticipant(env).firestore();
    await assertFails(
      setDoc(doc(db, 'users', 'p1'), {
        ...userData(),
        createdAt: daysAgo(30),
      }),
    );
  });

  it('refuses an unknown role', async () => {
    const db = asParticipant(env).firestore();
    await assertFails(
      setDoc(doc(db, 'users', 'p1'), {
        ...userData({ role: 'admin' }),
        createdAt: serverTimestamp(),
      }),
    );
  });

  it('refuses an email that does not match the token', async () => {
    const db = asParticipant(env, 'p1').firestore();
    await assertFails(
      setDoc(doc(db, 'users', 'p1'), {
        ...userData({ email: 'someone.else@example.com' }),
        createdAt: serverTimestamp(),
      }),
    );
  });

  it('[P-1] refuses a self-promotion to organizer', async () => {
    await seed((db) =>
      setDoc(doc(db, 'users', 'p1'), {
        ...userData(),
        createdAt: serverTimestamp(),
      }),
    );
    const db = asParticipant(env, 'p1').firestore();
    await assertFails(updateDoc(doc(db, 'users', 'p1'), { role: 'organizer' }));
  });

  it('refuses changing the email of an existing profile', async () => {
    await seed((db) =>
      setDoc(doc(db, 'users', 'p1'), {
        ...userData(),
        createdAt: serverTimestamp(),
      }),
    );
    const db = asParticipant(env, 'p1').firestore();
    await assertFails(
      updateDoc(doc(db, 'users', 'p1'), { email: 'other@example.com' }),
    );
  });

  it('allows editing presentation fields only', async () => {
    await seed((db) =>
      setDoc(doc(db, 'users', 'p1'), {
        ...userData(),
        createdAt: serverTimestamp(),
      }),
    );
    const db = asParticipant(env, 'p1').firestore();
    await assertSucceeds(
      updateDoc(doc(db, 'users', 'p1'), {
        name: 'Elie R.',
        bio: 'Développeur Flutter',
        updatedAt: serverTimestamp(),
      }),
    );
  });

  it('refuses reading another user profile', async () => {
    await seed((db) =>
      setDoc(doc(db, 'users', 'p2'), {
        ...userData({ email: 'p2@example.com' }),
        createdAt: serverTimestamp(),
      }),
    );
    const db = asParticipant(env, 'p1').firestore();
    await assertFails(getDoc(doc(db, 'users', 'p2')));
  });

  it('refuses enumerating the user base, even for an admin', async () => {
    const db = asAdmin(env).firestore();
    await assertFails(getDocs(query(collection(db, 'users'), limit(10))));
  });

  it('refuses deleting a profile', async () => {
    await seed((db) =>
      setDoc(doc(db, 'users', 'p1'), {
        ...userData(),
        createdAt: serverTimestamp(),
      }),
    );
    const db = asParticipant(env, 'p1').firestore();
    await assertFails(deleteDoc(doc(db, 'users', 'p1')));
  });
});

// ===========================================================================
//  events
// ===========================================================================

describe('events', () => {
  it('refuses creation by a participant', async () => {
    const db = asParticipant(env).firestore();
    await assertFails(
      setDoc(doc(db, 'events', 'e1'), {
        ...eventData({ organizerId: 'p1' }),
        createdAt: serverTimestamp(),
      }),
    );
  });

  it('allows an organizer to create a well-formed event', async () => {
    const db = asOrganizer(env, 'o1').firestore();
    await assertSucceeds(
      setDoc(doc(db, 'events', 'e1'), {
        ...eventData(),
        createdAt: serverTimestamp(),
      }),
    );
  });

  it('resolves the role from the profile document when no claim is present', async () => {
    await seed((db) =>
      setDoc(doc(db, 'users', 'o2'), {
        name: 'Hasina R.',
        email: 'o2@example.com',
        role: 'organizer',
        createdAt: serverTimestamp(),
      }),
    );
    const db = asClaimless(env, 'o2').firestore();
    await assertSucceeds(
      setDoc(doc(db, 'events', 'e2'), {
        ...eventData({ organizerId: 'o2' }),
        createdAt: serverTimestamp(),
      }),
    );
  });

  it('refuses an event that starts with seats already taken', async () => {
    const db = asOrganizer(env, 'o1').firestore();
    await assertFails(
      setDoc(doc(db, 'events', 'e1'), {
        ...eventData({ capacity: 10, availablePlaces: 4 }),
        createdAt: serverTimestamp(),
      }),
    );
  });

  it('refuses an event in the past', async () => {
    const db = asOrganizer(env, 'o1').firestore();
    await assertFails(
      setDoc(doc(db, 'events', 'e1'), {
        ...eventData({ startsAt: daysAgo(1) }),
        createdAt: serverTimestamp(),
      }),
    );
  });

  it('refuses an unknown field', async () => {
    const db = asOrganizer(env, 'o1').firestore();
    await assertFails(
      setDoc(doc(db, 'events', 'e1'), {
        ...eventData(),
        featured: true,
        createdAt: serverTimestamp(),
      }),
    );
  });

  it('refuses an organizerId that is not the caller', async () => {
    const db = asOrganizer(env, 'o1').firestore();
    await assertFails(
      setDoc(doc(db, 'events', 'e1'), {
        ...eventData({ organizerId: 'o2' }),
        createdAt: serverTimestamp(),
      }),
    );
  });

  it('[P-2] refuses an organizer editing somebody else’s event', async () => {
    await seedEvent('e1', { organizerId: 'o1' });
    const db = asOrganizer(env, 'o2').firestore();
    await assertFails(
      updateDoc(doc(db, 'events', 'e1'), { title: 'Titre détourné' }),
    );
  });

  it('lets the owner edit the content', async () => {
    await seedEvent('e1');
    const db = asOrganizer(env, 'o1').firestore();
    await assertSucceeds(
      updateDoc(doc(db, 'events', 'e1'), {
        title: 'Flutter Meetup — édition 2',
        updatedAt: serverTimestamp(),
      }),
    );
  });

  it('[P-5] refuses lowering the capacity below the seats already sold', async () => {
    // 10 seats, 3 sold.
    await seedEvent('e1', { capacity: 10, availablePlaces: 7 });
    const db = asOrganizer(env, 'o1').firestore();
    await assertFails(
      updateDoc(doc(db, 'events', 'e1'), {
        capacity: 2,
        availablePlaces: 0,
        updatedAt: serverTimestamp(),
      }),
    );
  });

  it('allows lowering the capacity down to the seats sold, preserving them', async () => {
    await seedEvent('e1', { capacity: 10, availablePlaces: 7 });
    const db = asOrganizer(env, 'o1').firestore();
    await assertSucceeds(
      updateDoc(doc(db, 'events', 'e1'), {
        capacity: 5,
        availablePlaces: 2, // 5 − 3 sold
        updatedAt: serverTimestamp(),
      }),
    );
  });

  it('refuses an owner edit that would erase the seats sold', async () => {
    await seedEvent('e1', { capacity: 10, availablePlaces: 7 });
    const db = asOrganizer(env, 'o1').firestore();
    await assertFails(
      updateDoc(doc(db, 'events', 'e1'), {
        capacity: 10,
        availablePlaces: 10,
        updatedAt: serverTimestamp(),
      }),
    );
  });

  it('lets a participant take exactly one seat', async () => {
    await seedEvent('e1', { capacity: 10, availablePlaces: 10 });
    const db = asParticipant(env, 'p1').firestore();
    await assertSucceeds(
      updateDoc(doc(db, 'events', 'e1'), {
        availablePlaces: 9,
        updatedAt: serverTimestamp(),
      }),
    );
  });

  it('[P-3] refuses a participant moving availablePlaces by more than one', async () => {
    await seedEvent('e1', { capacity: 10, availablePlaces: 10 });
    const db = asParticipant(env, 'p1').firestore();
    await assertFails(
      updateDoc(doc(db, 'events', 'e1'), { availablePlaces: 8 }),
    );
  });

  it('refuses a participant smuggling another field alongside the seat', async () => {
    await seedEvent('e1', { capacity: 10, availablePlaces: 10 });
    const db = asParticipant(env, 'p1').firestore();
    await assertFails(
      updateDoc(doc(db, 'events', 'e1'), {
        availablePlaces: 9,
        title: 'Titre détourné',
      }),
    );
  });

  it('refuses booking once the event has started', async () => {
    await seedEvent('e1', {
      startsAt: daysAgo(1),
      capacity: 10,
      availablePlaces: 10,
    });
    const db = asParticipant(env, 'p1').firestore();
    await assertFails(
      updateDoc(doc(db, 'events', 'e1'), { availablePlaces: 9 }),
    );
  });

  it('still allows releasing a seat after the event has started', async () => {
    await seedEvent('e1', {
      startsAt: daysAgo(1),
      capacity: 10,
      availablePlaces: 9,
    });
    const db = asParticipant(env, 'p1').firestore();
    await assertSucceeds(
      updateDoc(doc(db, 'events', 'e1'), { availablePlaces: 10 }),
    );
  });

  it('refuses deleting an event that has sold seats', async () => {
    await seedEvent('e1', { capacity: 10, availablePlaces: 7 });
    const db = asOrganizer(env, 'o1').firestore();
    await assertFails(deleteDoc(doc(db, 'events', 'e1')));
  });

  it('allows deleting an empty event', async () => {
    await seedEvent('e1', { capacity: 10, availablePlaces: 10 });
    const db = asOrganizer(env, 'o1').firestore();
    await assertSucceeds(deleteDoc(doc(db, 'events', 'e1')));
  });

  it('refuses reading the catalogue anonymously', async () => {
    await seedEvent('e1');
    const db = asAnonymous(env).firestore();
    await assertFails(getDoc(doc(db, 'events', 'e1')));
  });

  it('[P-6] refuses an unbounded list query and accepts a bounded one', async () => {
    await seedEvent('e1');
    const db = asParticipant(env, 'p1').firestore();

    // No `.limit()` — the comparison in the rule cannot be satisfied.
    await assertFails(getDocs(collection(db, 'events')));

    // Bounded below the ceiling declared in the rules.
    await assertSucceeds(
      getDocs(query(collection(db, 'events'), limit(100))),
    );
  });

  it('refuses a list query above the ceiling', async () => {
    await seedEvent('e1');
    const db = asParticipant(env, 'p1').firestore();
    await assertFails(getDocs(query(collection(db, 'events'), limit(500))));
  });
});

// ===========================================================================
//  reservations
// ===========================================================================

describe('reservations', () => {
  beforeEach(async () => {
    await seedEvent('e1', { capacity: 10, availablePlaces: 10 });
  });

  it('accepts a well-formed reservation at its deterministic id', async () => {
    const db = asParticipant(env, 'p1').firestore();
    await assertSucceeds(
      setDoc(
        doc(db, 'reservations', reservationId('e1', 'p1')),
        reservationData(),
      ),
    );
  });

  it('refuses a reservation stored under a non-deterministic id', async () => {
    const db = asParticipant(env, 'p1').firestore();
    await assertFails(
      setDoc(doc(db, 'reservations', 'whatever'), reservationData()),
    );
  });

  it('refuses a reservation created on behalf of another user', async () => {
    const db = asParticipant(env, 'p1').firestore();
    await assertFails(
      setDoc(
        doc(db, 'reservations', reservationId('e1', 'p2')),
        reservationData({ userId: 'p2' }),
      ),
    );
  });

  it('[P-4] refuses a forged organizerId', async () => {
    const db = asParticipant(env, 'p1').firestore();
    await assertFails(
      setDoc(
        doc(db, 'reservations', reservationId('e1', 'p1')),
        reservationData({ organizerId: 'p1' }),
      ),
    );
  });

  it('refuses denormalised fields that do not match the event', async () => {
    const db = asParticipant(env, 'p1').firestore();
    await assertFails(
      setDoc(
        doc(db, 'reservations', reservationId('e1', 'p1')),
        reservationData({ eventTitle: 'Un autre événement' }),
      ),
    );
  });

  it('refuses a reservation on a sold-out event', async () => {
    await seedEvent('e2', { capacity: 10, availablePlaces: 0 });
    const db = asParticipant(env, 'p1').firestore();
    await assertFails(
      setDoc(
        doc(db, 'reservations', reservationId('e2', 'p1')),
        reservationData({ eventId: 'e2' }),
      ),
    );
  });

  it('refuses a reservation on a past event', async () => {
    await seedEvent('e3', {
      startsAt: daysAgo(1),
      capacity: 10,
      availablePlaces: 10,
    });
    const db = asParticipant(env, 'p1').firestore();
    await assertFails(
      setDoc(
        doc(db, 'reservations', reservationId('e3', 'p1')),
        reservationData({ eventId: 'e3', eventStartsAt: daysAgo(1) }),
      ),
    );
  });

  it('refuses a back-dated reservedAt', async () => {
    const db = asParticipant(env, 'p1').firestore();
    await assertFails(
      setDoc(
        doc(db, 'reservations', reservationId('e1', 'p1')),
        reservationData({ reservedAt: daysAgo(30) }),
      ),
    );
  });

  it('refuses a post-dated reservedAt', async () => {
    const db = asParticipant(env, 'p1').firestore();
    await assertFails(
      setDoc(
        doc(db, 'reservations', reservationId('e1', 'p1')),
        reservationData({ reservedAt: inDays(1) }),
      ),
    );
  });

  it('lets the owner cancel their reservation', async () => {
    await seedReservation(reservationId('e1', 'p1'));
    const db = asParticipant(env, 'p1').firestore();
    await assertSucceeds(
      updateDoc(doc(db, 'reservations', reservationId('e1', 'p1')), {
        status: 'cancelled',
        cancelledAt: new Date(),
      }),
    );
  });

  it('refuses cancelling somebody else’s reservation', async () => {
    await seedReservation(reservationId('e1', 'p1'));
    const db = asParticipant(env, 'p2').firestore();
    await assertFails(
      updateDoc(doc(db, 'reservations', reservationId('e1', 'p1')), {
        status: 'cancelled',
        cancelledAt: new Date(),
      }),
    );
  });

  it('[P-7] refuses deleting a reservation, always', async () => {
    await seedReservation(reservationId('e1', 'p1'));

    for (const ctx of [
      asParticipant(env, 'p1'),
      asOrganizer(env, 'o1'),
      asAdmin(env),
    ]) {
      await assertFails(
        deleteDoc(doc(ctx.firestore(), 'reservations', reservationId('e1', 'p1'))),
      );
    }
  });

  it('is readable by its participant and by the event organizer', async () => {
    await seedReservation(reservationId('e1', 'p1'));
    const id = reservationId('e1', 'p1');

    await assertSucceeds(
      getDoc(doc(asParticipant(env, 'p1').firestore(), 'reservations', id)),
    );
    await assertSucceeds(
      getDoc(doc(asOrganizer(env, 'o1').firestore(), 'reservations', id)),
    );
  });

  it('is not readable by an unrelated user', async () => {
    await seedReservation(reservationId('e1', 'p1'));
    await assertFails(
      getDoc(
        doc(
          asParticipant(env, 'p9').firestore(),
          'reservations',
          reservationId('e1', 'p1'),
        ),
      ),
    );
  });
});

// ===========================================================================
//  reviews
// ===========================================================================

describe('reviews', () => {
  const review = (overrides = {}) => ({
    eventId: 'e1',
    authorId: 'p1',
    authorName: 'Elie Rakoto',
    rating: 5,
    comment: 'Excellent événement.',
    createdAt: serverTimestamp(),
    ...overrides,
  });

  beforeEach(async () => {
    await seedEvent('e1');
    await seedReservation(reservationId('e1', 'p1'));
  });

  it('accepts a review from a confirmed attendee with a verified email', async () => {
    const db = asParticipant(env, 'p1').firestore();
    await assertSucceeds(
      setDoc(doc(db, 'reviews', reservationId('e1', 'p1')), review()),
    );
  });

  it('refuses a review from an unverified account', async () => {
    const db = asParticipant(env, 'p1', { email_verified: false }).firestore();
    await assertFails(
      setDoc(doc(db, 'reviews', reservationId('e1', 'p1')), review()),
    );
  });

  it('refuses a review from someone who never attended', async () => {
    const db = asParticipant(env, 'p9').firestore();
    await assertFails(
      setDoc(
        doc(db, 'reviews', reservationId('e1', 'p9')),
        review({ authorId: 'p9' }),
      ),
    );
  });

  it('refuses a rating outside 1..5', async () => {
    const db = asParticipant(env, 'p1').firestore();
    await assertFails(
      setDoc(
        doc(db, 'reviews', reservationId('e1', 'p1')),
        review({ rating: 9 }),
      ),
    );
  });
});

// ===========================================================================
//  closed collections and the catch-all
// ===========================================================================

describe('closed collections', () => {
  it('keeps the audit trail invisible to every client', async () => {
    await seed((db) => setDoc(doc(db, 'audit', 'a1'), { action: 'x' }));

    for (const ctx of [asParticipant(env), asOrganizer(env), asAdmin(env)]) {
      await assertFails(getDoc(doc(ctx.firestore(), 'audit', 'a1')));
    }
  });

  it('exposes config read-only', async () => {
    await seed((db) => setDoc(doc(db, 'config', 'remote'), { flag: true }));
    const db = asAnonymous(env).firestore();

    await assertSucceeds(getDoc(doc(db, 'config', 'remote')));
    await assertFails(setDoc(doc(db, 'config', 'remote'), { flag: false }));
  });

  it('denies any collection nobody wrote a rule for', async () => {
    const db = asAdmin(env).firestore();
    await assertFails(setDoc(doc(db, 'not_a_real_collection', 'x'), { a: 1 }));
    await assertFails(getDoc(doc(db, 'not_a_real_collection', 'x')));
  });

  it('gives each user a private subtree nobody else can read', async () => {
    await seed((db) =>
      setDoc(doc(db, 'users', 'p1', 'private', 'prefs'), { locale: 'fr' }),
    );

    await assertSucceeds(
      getDoc(doc(asParticipant(env, 'p1').firestore(), 'users', 'p1', 'private', 'prefs')),
    );
    await assertFails(
      getDoc(doc(asParticipant(env, 'p2').firestore(), 'users', 'p1', 'private', 'prefs')),
    );
  });
});

// A sanity check that the suite itself is wired to the right project.
describe('harness', () => {
  it('runs against the demo project', () => {
    assert.equal(env.projectId, 'demo-eventhub');
  });
});
