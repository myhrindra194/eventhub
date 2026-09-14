// Integration tests of the Cloud Functions, run against the local emulators:
//
//   make test-functions
//   (= firebase emulators:exec --project demo-eventhub
//        --only auth,firestore,functions,storage "npm --prefix functions test")
//
// Triggers are exercised the way production exercises them: by writing
// documents and watching the effects. FCM is not emulated — no device is
// registered, so `notify` stops after writing the in-app notification, which
// is exactly what these tests observe.

import assert from 'node:assert/strict';
import { after, before, beforeEach, describe, it } from 'node:test';
import { createRequire } from 'node:module';

const require = createRequire(import.meta.url);
const { initializeApp, getApps } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');

const PROJECT_ID = process.env.GCLOUD_PROJECT ?? 'demo-eventhub';
const REGION = 'us-central1';
const HOUR = 3_600_000;

if (!process.env.FIRESTORE_EMULATOR_HOST) {
  throw new Error('Run through `firebase emulators:exec` (see header).');
}

let db;
let auth;

before(() => {
  // No options, exactly like functions/src/index.ts: the emulator exports
  // GCLOUD_PROJECT, and requiring lib/index.js later reuses this app instead
  // of failing on a "[DEFAULT] app with a different configuration".
  if (getApps().length === 0) initializeApp();
  db = getFirestore();
  auth = getAuth();
});

after(async () => {
  await db?.terminate();
});

beforeEach(async () => {
  await fetch(
    `http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/${PROJECT_ID}/databases/(default)/documents`,
    { method: 'DELETE' },
  );
});

/** Polls until [probe] returns a truthy value or the timeout elapses. */
async function eventually(probe, { timeout = 15_000, interval = 250 } = {}) {
  const deadline = Date.now() + timeout;
  for (;;) {
    const value = await probe();
    if (value) return value;
    if (Date.now() > deadline) return value;
    await new Promise((r) => setTimeout(r, interval));
  }
}

const eventDoc = (overrides = {}) => ({
  title: 'Flutter Meetup',
  description: 'Talks et live coding.',
  category: 'meetup',
  startsAt: Timestamp.fromMillis(Date.now() + 7 * 24 * HOUR),
  location: 'Antananarivo',
  capacity: 10,
  availablePlaces: 10,
  organizerId: 'o1',
  organizerName: 'Mirindra',
  createdAt: Timestamp.now(),
  ...overrides,
});

const reservationDoc = (overrides = {}) => ({
  eventId: 'e1',
  userId: 'p1',
  organizerId: 'o1',
  userName: 'Jean Rakoto',
  userEmail: 'jean@example.com',
  eventTitle: 'Flutter Meetup',
  eventStartsAt: Timestamp.fromMillis(Date.now() + 7 * 24 * HOUR),
  eventLocation: 'Antananarivo',
  status: 'confirmed',
  reservedAt: Timestamp.now(),
  ...overrides,
});

const notificationsOf = async (uid) =>
  (await db.collection(`users/${uid}/notifications`).get()).docs.map((d) =>
    d.data(),
  );

// ---------------------------------------------------------------------------

describe('setRoleClaim', () => {
  it('copies the profile role into a custom claim', async () => {
    const { uid } = await auth.createUser({
      email: `org-${Date.now()}@example.com`,
      password: 'secret123',
    });
    await db.doc(`users/${uid}`).set({
      name: 'Mirindra',
      email: 'org@example.com',
      role: 'organizer',
      createdAt: Timestamp.now(),
    });

    const claims = await eventually(async () => {
      const user = await auth.getUser(uid);
      return user.customClaims?.role ? user.customClaims : null;
    });
    assert.equal(claims?.role, 'organizer');
  });
});

describe('notifyOrganizerOnReservation', () => {
  it('writes a booking notification for the organizer', async () => {
    await db.doc('reservations/e1_p1').set(reservationDoc());

    const items = await eventually(async () => {
      const list = await notificationsOf('o1');
      return list.length > 0 ? list : null;
    });
    assert.equal(items?.[0].type, 'booking');
    assert.equal(items?.[0].eventId, 'e1');
    assert.match(items?.[0].body, /Jean Rakoto/);
    assert.ok(items?.[0].expiresAt, 'TTL field set');
  });

  it('writes a cancellation notification on confirmed → cancelled', async () => {
    await db.doc('reservations/e1_p1').set(reservationDoc());
    await eventually(async () => (await notificationsOf('o1')).length === 1);

    await db
      .doc('reservations/e1_p1')
      .update({ status: 'cancelled', cancelledAt: Timestamp.now() });

    const items = await eventually(async () => {
      const list = await notificationsOf('o1');
      return list.some((n) => n.type === 'cancellation') ? list : null;
    });
    assert.ok(items, 'cancellation notified');
  });

  it('respects an organizer who turned booking alerts off', async () => {
    await db.doc('users/o1/private/notifications').set({ bookingAlerts: false });
    await db.doc('reservations/e1_p1').set(reservationDoc());

    await new Promise((r) => setTimeout(r, 4_000));
    assert.deepEqual(await notificationsOf('o1'), []);
  });

  it('removes the participant from the waiting list when they book', async () => {
    await db.doc('events/e1').set(eventDoc({ availablePlaces: 0 }));
    await db
      .doc('events/e1/waitlist/p1')
      .set({ userId: 'p1', userName: 'Jean', createdAt: Timestamp.now() });

    await db.doc('reservations/e1_p1').set(reservationDoc());

    const gone = await eventually(
      async () => !(await db.doc('events/e1/waitlist/p1').get()).exists,
    );
    assert.ok(gone, 'waitlist entry deleted');
  });
});

describe('notifyWaitlistOnSeatRelease', () => {
  it('notifies the oldest waiting people, one per seat freed', async () => {
    await db.doc('events/e1').set(eventDoc({ availablePlaces: 0 }));
    await db.doc('events/e1/waitlist/p1').set({
      userId: 'p1',
      userName: 'Premier',
      createdAt: Timestamp.fromMillis(Date.now() - 2 * HOUR),
    });
    await db.doc('events/e1/waitlist/p2').set({
      userId: 'p2',
      userName: 'Second',
      createdAt: Timestamp.fromMillis(Date.now() - HOUR),
    });

    await db.doc('events/e1').update({ availablePlaces: 1 });

    const notified = await eventually(
      async () => (await db.doc('events/e1/waitlist/p1').get()).get('notifiedAt'),
    );
    assert.ok(notified, 'first in line stamped');
    assert.equal((await notificationsOf('p1'))[0]?.type, 'waitlist');

    await new Promise((r) => setTimeout(r, 2_000));
    assert.equal(
      (await db.doc('events/e1/waitlist/p2').get()).get('notifiedAt'),
      undefined,
      'only as many people as seats freed',
    );
  });
});

describe('runEventReminders', () => {
  it('reminds holders of events starting in 23–24 h, once each', async () => {
    const { runEventReminders } = require('../lib/index.js');
    const now = Date.now();
    await db.doc('reservations/soon_p1').set(
      reservationDoc({
        eventId: 'soon',
        eventStartsAt: Timestamp.fromMillis(now + 23.5 * HOUR),
      }),
    );
    await db.doc('reservations/later_p1').set(
      reservationDoc({
        eventId: 'later',
        eventStartsAt: Timestamp.fromMillis(now + 30 * HOUR),
      }),
    );
    await db.doc('reservations/gone_p2').set(
      reservationDoc({
        eventId: 'soon',
        userId: 'p2',
        status: 'cancelled',
        eventStartsAt: Timestamp.fromMillis(now + 23.5 * HOUR),
      }),
    );

    const result = await runEventReminders(now);
    assert.deepEqual(result, { candidates: 1, sent: 1 });
    const items = await notificationsOf('p1');
    assert.equal(items.length, 1);
    assert.equal(items[0].type, 'reminder');
    assert.equal(items[0].reservationId, 'soon_p1');
  });
});

describe('public organizer profile (F-10)', () => {
  const organizerProfile = async (uid) =>
    eventually(async () => {
      const snap = await db.doc(`organizers/${uid}`).get();
      return snap.exists ? snap : null;
    });

  it('publishes name and bio of an organizer, never email or role', async () => {
    await db.doc('users/o1').set({
      name: 'Mirindra',
      email: 'o1@example.com',
      role: 'organizer',
      bio: 'Meetups Flutter à Tana.',
      createdAt: Timestamp.now(),
    });
    const snap = await organizerProfile('o1');
    assert.equal(snap?.get('name'), 'Mirindra');
    assert.equal(snap?.get('bio'), 'Meetups Flutter à Tana.');
    assert.equal(snap?.get('email'), undefined);
    assert.equal(snap?.get('role'), undefined);

    await db.doc('users/o1').update({ bio: 'Nouvelle bio.' });
    const updated = await eventually(async () => {
      const s = await db.doc('organizers/o1').get();
      return s.get('bio') === 'Nouvelle bio.' ? s : null;
    });
    assert.ok(updated, 'bio change propagated');
  });

  it('does not publish a participant', async () => {
    await db.doc('users/p1').set({
      name: 'Jean',
      email: 'p1@example.com',
      role: 'participant',
      createdAt: Timestamp.now(),
    });
    await new Promise((r) => setTimeout(r, 3_000));
    assert.equal((await db.doc('organizers/p1').get()).exists, false);
  });

  it('counts followers once per follow and mirrors them server-side', async () => {
    await db.doc('organizers/o1').set({ name: 'Mirindra' });
    await db.doc('users/p1/following/o1').set({ organizerId: 'o1', createdAt: Timestamp.now() });
    await db.doc('users/p2/following/o1').set({ organizerId: 'o1', createdAt: Timestamp.now() });

    const counted = await eventually(async () =>
      (await db.doc('organizers/o1').get()).get('followerCount') === 2,
    );
    assert.ok(counted, 'two followers');
    assert.ok((await db.doc('organizers/o1/followers/p1').get()).exists);

    await db.doc('users/p1/following/o1').delete();
    const decremented = await eventually(async () =>
      (await db.doc('organizers/o1').get()).get('followerCount') === 1,
    );
    assert.ok(decremented, 'unfollow decrements');
    assert.equal((await db.doc('organizers/o1/followers/p1').get()).exists, false);
  });

  it('announces a new event to followers who did not opt out', async () => {
    await db.doc('organizers/o1').set({ name: 'Mirindra' });
    await db.doc('organizers/o1/followers/p1').set({ userId: 'p1' });
    await db.doc('organizers/o1/followers/p2').set({ userId: 'p2' });
    await db.doc('users/p2/private/notifications').set({ followedOrganizers: false });

    await db.doc('events/e1').set(eventDoc());

    const items = await eventually(async () => {
      const list = await notificationsOf('p1');
      return list.length > 0 ? list : null;
    });
    assert.equal(items?.[0].type, 'newEvent');
    assert.equal(items?.[0].eventId, 'e1');
    assert.match(items?.[0].title, /Mirindra/);
    const counted = await eventually(async () =>
      (await db.doc('organizers/o1').get()).get('eventCount') === 1,
    );
    assert.ok(counted, 'eventCount incremented');
    await new Promise((r) => setTimeout(r, 1_500));
    assert.deepEqual(await notificationsOf('p2'), [], 'opt-out respected');
  });

  it('averages visible review ratings on the organizer', async () => {
    await db.doc('organizers/o1').set({ name: 'Mirindra' });
    await db.doc('events/e1').set(eventDoc());
    const review = (authorId, rating) => ({
      eventId: 'e1',
      authorId,
      authorName: authorId,
      rating,
      comment: '',
      createdAt: Timestamp.now(),
    });
    await db.doc('reviews/e1_p1').set(review('p1', 5));
    await db.doc('reviews/e1_p2').set(review('p2', 2));

    const both = await eventually(async () => {
      const s = await db.doc('organizers/o1').get();
      return s.get('ratingCount') === 2 && s.get('ratingSum') === 7;
    });
    assert.ok(both, 'sum 7 over 2 reviews');

    await db.doc('reviews/e1_p2').update({ hidden: true });
    const hidden = await eventually(async () => {
      const s = await db.doc('organizers/o1').get();
      return s.get('ratingCount') === 1 && s.get('ratingSum') === 5;
    });
    assert.ok(hidden, 'hidden review no longer counts');
  });
});

describe('aggregateAttendance (F-07)', () => {
  const recent = async () =>
    (await db.doc('aggregates/event_e1').get()).get('recentAttendees') ?? [];

  it('lists short names of the latest bookers and removes cancellations', async () => {
    await db.doc('reservations/e1_p1').set(
      reservationDoc({ userId: 'p1', userName: 'Jean-Marc Rakotomalala' }),
    );
    await eventually(async () => (await recent()).length === 1);
    await db.doc('reservations/e1_p2').set(
      reservationDoc({ userId: 'p2', userName: 'Soa' }),
    );
    const two = await eventually(async () => {
      const list = await recent();
      return list.length === 2 ? list : null;
    });
    assert.deepEqual(
      two?.map((a) => a.name),
      ['Soa', 'Jean-Marc R.'],
      'most recent first, surname initial only',
    );
    assert.ok(two?.every((a) => !JSON.stringify(a).includes('p1')), 'no uid');

    await db
      .doc('reservations/e1_p1')
      .update({ status: 'cancelled', cancelledAt: Timestamp.now() });
    const one = await eventually(async () => {
      const list = await recent();
      return list.length === 1 ? list : null;
    });
    assert.equal(one?.[0].name, 'Soa');
  });
});

describe('moderation (F-19)', () => {
  const fileReport = (reporterId, overrides = {}) => {
    const r = {
      targetType: 'review',
      targetId: 'e1_p9',
      reason: 'harassment',
      details: '',
      reporterId,
      createdAt: Timestamp.now(),
      ...overrides,
    };
    return db.doc(`reports/${r.targetType}_${r.targetId}_${reporterId}`).set(r);
  };

  it('hides a review once three distinct people reported it', async () => {
    await db.doc('reviews/e1_p9').set({
      eventId: 'e1',
      authorId: 'p9',
      authorName: 'Troll',
      rating: 1,
      comment: 'Texte abusif',
      createdAt: Timestamp.now(),
    });
    await fileReport('p1');
    await fileReport('p2');
    await eventually(async () =>
      (await db.doc('moderationQueue/review_e1_p9').get()).get('reportCount') === 2,
    );
    assert.equal((await db.doc('reviews/e1_p9').get()).get('hidden'), undefined);

    await fileReport('p3');
    const hidden = await eventually(async () =>
      (await db.doc('reviews/e1_p9').get()).get('hidden') === true,
    );
    assert.ok(hidden, 'hidden at threshold');
    const queue = (await db.doc('moderationQueue/review_e1_p9').get()).data();
    assert.equal(queue.status, 'open');
    assert.equal(queue.reportCount, 3);
  });

  it('never removes an event automatically, only queues it', async () => {
    await db.doc('events/e1').set(eventDoc());
    for (const p of ['p1', 'p2', 'p3', 'p4', 'p5']) {
      await fileReport(p, { targetType: 'event', targetId: 'e1', reason: 'fraud' });
    }
    await eventually(async () =>
      (await db.doc('moderationQueue/event_e1').get()).get('reportCount') === 5,
    );
    assert.equal((await db.doc('events/e1').get()).exists, true);
  });

  it('lets an admin restore a hidden review, and only an admin', async () => {
    await db.doc('reviews/e1_p9').set({
      eventId: 'e1',
      authorId: 'p9',
      authorName: 'Jean',
      rating: 4,
      comment: 'Bien',
      hidden: true,
      createdAt: Timestamp.now(),
    });
    const host = process.env.FUNCTIONS_EMULATOR_HOST ?? '127.0.0.1:5001';
    const call = (idToken) =>
      fetch(`http://${host}/${PROJECT_ID}/${REGION}/moderateContent`, {
        method: 'POST',
        headers: {
          'content-type': 'application/json',
          authorization: `Bearer ${idToken}`,
        },
        body: JSON.stringify({
          data: { targetType: 'review', targetId: 'e1_p9', action: 'restore' },
        }),
      });

    const user = await signUp(`user-${Date.now()}@example.com`);
    assert.notEqual((await call(user.idToken)).status, 200, 'non-admin refused');

    const admin = await signUp(`admin-${Date.now()}@example.com`);
    await auth.setCustomUserClaims(admin.uid, { admin: true });
    const refreshed = await signIn(admin.email);
    const res = await call(refreshed.idToken);
    assert.equal(res.status, 200);
    const review = (await db.doc('reviews/e1_p9').get()).data();
    assert.equal(review.hidden, false);
    assert.ok(review.moderatedAt, 'decision stamped');
  });
});

describe('publicEventPage (F-08)', () => {
  const host = () => process.env.FUNCTIONS_EMULATOR_HOST ?? '127.0.0.1:5001';
  const page = (path) =>
    fetch(`http://${host()}/${PROJECT_ID}/${REGION}/publicEventPage${path}`, {
      redirect: 'manual',
    });

  it('renders an event with Open Graph tags, escaping user content', async () => {
    await db.doc('events/e1').set(
      eventDoc({
        title: 'Flutter <script>alert(1)</script> Meetup',
        availablePlaces: 3,
        imageUrl: 'https://example.com/cover.jpg',
      }),
    );
    const res = await page('/e/e1');
    assert.equal(res.status, 200);
    assert.match(res.headers.get('content-type') ?? '', /text\/html/);
    const html = await res.text();
    assert.match(html, /<meta property="og:title" content="Flutter &lt;script&gt;alert\(1\)&lt;\/script&gt; Meetup">/);
    assert.match(html, /og:image" content="https:\/\/example.com\/cover.jpg"/);
    assert.match(html, /3 places sur 10 encore libres/);
    assert.ok(!html.includes('<script>'), 'no raw script tag');
    assert.ok(!html.includes('jean@example.com'), 'no attendee data');
  });

  it('answers 404 for an unknown event and redirects other paths home', async () => {
    assert.equal((await page('/e/does-not-exist')).status, 404);
    assert.equal((await page('/nothing')).status, 302);
  });
});

/** Signs a user up on the Auth emulator. */
async function signUp(email) {
  const res = await fetch(
    `http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake`,
    {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ email, password: 'secret123', returnSecureToken: true }),
    },
  );
  const body = await res.json();
  return { idToken: body.idToken, uid: body.localId, email };
}

/** Signs in again, so the ID token carries freshly set custom claims. */
async function signIn(email) {
  const res = await fetch(
    `http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=fake`,
    {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ email, password: 'secret123', returnSecureToken: true }),
    },
  );
  const body = await res.json();
  return { idToken: body.idToken, uid: body.localId };
}

describe('deleteAccount (callable)', () => {
  /** Signs a user up on the Auth emulator and returns an ID token. */
  async function idTokenFor(email) {
    const res = await fetch(
      `http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake`,
      {
        method: 'POST',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({ email, password: 'secret123', returnSecureToken: true }),
      },
    );
    const body = await res.json();
    return { idToken: body.idToken, uid: body.localId };
  }

  async function callDelete(idToken) {
    const host = process.env.FUNCTIONS_EMULATOR_HOST ?? '127.0.0.1:5001';
    const res = await fetch(
      `http://${host}/${PROJECT_ID}/${REGION}/deleteAccount`,
      {
        method: 'POST',
        headers: {
          'content-type': 'application/json',
          authorization: `Bearer ${idToken}`,
        },
        body: JSON.stringify({ data: {} }),
      },
    );
    return { status: res.status, body: await res.json() };
  }

  it('deletes a participant, releases upcoming seats and anonymises history', async () => {
    const { idToken, uid } = await idTokenFor(`p-${Date.now()}@example.com`);
    await db.doc(`users/${uid}`).set({
      name: 'Jean',
      email: 'jean@example.com',
      role: 'participant',
      createdAt: Timestamp.now(),
    });
    await db.doc(`users/${uid}/favorites/e1`).set({ eventId: 'e1', createdAt: Timestamp.now() });
    await db.doc('events/e1').set(eventDoc({ availablePlaces: 9 }));
    await db.doc(`reservations/e1_${uid}`).set(reservationDoc({ userId: uid }));

    const { status } = await callDelete(idToken);
    assert.equal(status, 200);

    assert.equal((await db.doc(`users/${uid}`).get()).exists, false);
    assert.equal((await db.doc(`users/${uid}/favorites/e1`).get()).exists, false);
    assert.equal((await db.doc('events/e1').get()).get('availablePlaces'), 10);
    const r = (await db.doc(`reservations/e1_${uid}`).get()).data();
    assert.equal(r.status, 'cancelled');
    assert.equal(r.userName, 'Compte supprimé');
    await assert.rejects(auth.getUser(uid), 'Auth user removed');
  });

  it('refuses an organizer whose upcoming event has participants', async () => {
    const { idToken, uid } = await idTokenFor(`o-${Date.now()}@example.com`);
    await db.doc(`users/${uid}`).set({
      name: 'Mirindra',
      email: 'org@example.com',
      role: 'organizer',
      createdAt: Timestamp.now(),
    });
    await db.doc('events/e1').set(eventDoc({ organizerId: uid, availablePlaces: 7 }));

    const { status, body } = await callDelete(idToken);
    assert.equal(status, 400);
    assert.equal(body.error?.status, 'FAILED_PRECONDITION');
    assert.equal((await db.doc(`users/${uid}`).get()).exists, true);
  });

  it('refuses an anonymous call', async () => {
    const { status } = await callDelete('not-a-token');
    assert.notEqual(status, 200);
  });
});
