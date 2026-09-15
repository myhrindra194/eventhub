import { after, beforeEach, describe, test } from 'node:test';

import {
  Timestamp, collection, deleteDoc, doc, getDoc, getDocs, increment, limit, query, updateDoc, where, writeBatch,
} from 'firebase/firestore';

import {
  as, asAnonymous, assertFails, assertSucceeds, createTestEnv, eventData, inDays, seed, seedAdmin, seedUser,
  serverTimestamp,
} from './helpers.js';

const env = await createTestEnv();
after(() => env.cleanup());
beforeEach(async () => {
  await env.clearFirestore();
  await seedUser(env, 'o1', { role: 'organizer' });
});

function publish(db, eventId, data, { count = true } = {}) {
  const batch = writeBatch(db);
  batch.set(doc(db, `events/${eventId}`), { ...data, createdAt: serverTimestamp() });
  if (count) batch.update(doc(db, 'organizers/o1'), { eventCount: increment(1), lastEventId: eventId });
  return batch.commit();
}

describe('publishing', () => {
  test('an organizer publishes and the page counts it', async () => {
    const db = as(env, 'o1').firestore();
    await assertSucceeds(publish(db, 'e1', eventData()));
    await env.withSecurityRulesDisabled(async (ctx) => {
      const page = await getDoc(doc(ctx.firestore(), 'organizers/o1'));
      if (page.data().eventCount !== 1) throw new Error('eventCount not incremented');
    });
  });

  test('the page counter cannot be skipped', async () => {
    await assertFails(publish(as(env, 'o1').firestore(), 'e1', eventData(), { count: false }));
  });

  test('the page counter cannot be bumped without an event', async () => {
    const db = as(env, 'o1').firestore();
    await assertFails(updateDoc(doc(db, 'organizers/o1'), { eventCount: increment(1), lastEventId: 'ghost' }));
  });

  test('a participant cannot publish', async () => {
    await seedUser(env, 'p1');
    await assertFails(publish(as(env, 'p1').firestore(), 'e1', eventData({ organizerId: 'p1', organizerName: 'Name p1' })));
  });

  test('an unverified organizer cannot publish', async () => {
    await assertFails(publish(as(env, 'o1', { verified: false }).firestore(), 'e1', eventData()));
  });

  test('nobody publishes in somebody else\'s name', async () => {
    await seedUser(env, 'o2', { role: 'organizer' });
    await assertFails(publish(as(env, 'o2').firestore(), 'e1', eventData()));
  });

  test('a new event starts empty, in the future, without a team', async () => {
    const db = as(env, 'o1').firestore();
    await assertFails(publish(db, 'e1', eventData({ availablePlaces: 3 })));
    await assertFails(publish(db, 'e2', eventData({ startsAt: Timestamp.fromMillis(Date.now() - 60_000) })));
    await assertFails(publish(db, 'e3', eventData({ staffIds: ['o2'] })));
    await assertFails(publish(db, 'e4', eventData({ imageUrl: 'http://insecure.example/cover.png' })));
  });
});

describe('reading', () => {
  test('an event is public; the catalogue needs an account and a bounded page', async () => {
    await seed(env, [['events/e1', eventData()]]);
    await assertSucceeds(getDoc(doc(asAnonymous(env).firestore(), 'events/e1')));
    await assertFails(getDocs(query(collection(asAnonymous(env).firestore(), 'events'), limit(10))));
    await seedUser(env, 'p1');
    const db = as(env, 'p1').firestore();
    await assertSucceeds(getDocs(query(collection(db, 'events'), limit(50))));
    await assertFails(getDocs(collection(db, 'events')));
  });
});

describe('editing', () => {
  beforeEach(() => seed(env, [['events/e1', eventData({ capacity: 10, availablePlaces: 6 })]]));

  test('the owner edits content and capacity keeps sold seats', async () => {
    const db = as(env, 'o1').firestore();
    await assertSucceeds(updateDoc(doc(db, 'events/e1'), { title: 'Nouveau titre', capacity: 20, availablePlaces: 16 }));
  });

  test('capacity cannot drop below the seats sold', async () => {
    await assertFails(updateDoc(doc(as(env, 'o1').firestore(), 'events/e1'), { capacity: 3, availablePlaces: 0 }));
  });

  test('seats cannot be conjured by editing the counter', async () => {
    await assertFails(updateDoc(doc(as(env, 'o1').firestore(), 'events/e1'), { availablePlaces: 10 }));
  });

  test('a co-organizer edits, a stranger does not', async () => {
    await seedUser(env, 'o2', { role: 'organizer' });
    await seedUser(env, 'o3', { role: 'organizer' });
    await seed(env, [['events/e1', eventData({ capacity: 10, availablePlaces: 6, staffIds: ['o2'] })]]);
    await assertSucceeds(updateDoc(doc(as(env, 'o2').firestore(), 'events/e1'), { location: 'Toamasina' }));
    await assertFails(updateDoc(doc(as(env, 'o3').firestore(), 'events/e1'), { location: 'Toamasina' }));
  });

  test('the organizer cannot be swapped', async () => {
    await seedUser(env, 'o2', { role: 'organizer' });
    await assertFails(updateDoc(doc(as(env, 'o1').firestore(), 'events/e1'), { organizerId: 'o2' }));
  });

  test('the team is never edited through the content form', async () => {
    await assertFails(updateDoc(doc(as(env, 'o1').firestore(), 'events/e1'), { staffIds: ['o9'] }));
  });
});

describe('deleting', () => {
  function remove(db, eventId) {
    const batch = writeBatch(db);
    batch.delete(doc(db, `events/${eventId}`));
    batch.update(doc(db, 'organizers/o1'), { eventCount: increment(-1), lastEventId: eventId });
    return batch.commit();
  }

  test('an event nobody booked is deleted by its owner', async () => {
    await seed(env, [['events/e1', eventData()], ['organizers/o1', {
      name: 'Name o1', bio: '', memberSince: Timestamp.now(), followerCount: 0, eventCount: 1, ratingSum: 0, ratingCount: 0,
    }]]);
    await assertSucceeds(remove(as(env, 'o1').firestore(), 'e1'));
  });

  test('an event with bookings is not deleted', async () => {
    await seed(env, [['events/e1', eventData({ availablePlaces: 9 })], ['organizers/o1', {
      name: 'Name o1', bio: '', memberSince: Timestamp.now(), followerCount: 0, eventCount: 1, ratingSum: 0, ratingCount: 0,
    }]]);
    await assertFails(remove(as(env, 'o1').firestore(), 'e1'));
  });

  test('a co-organizer cannot delete, moderation can', async () => {
    await seedUser(env, 'o2', { role: 'organizer' });
    await seedAdmin(env, 'a1');
    await seed(env, [['events/e1', eventData({ staffIds: ['o2'], availablePlaces: 4 })]]);
    await assertFails(deleteDoc(doc(as(env, 'o2').firestore(), 'events/e1')));
    await assertSucceeds(deleteDoc(doc(as(env, 'a1').firestore(), 'events/e1')));
  });
});

describe('team', () => {
  beforeEach(async () => {
    await seedUser(env, 'o2', { role: 'organizer' });
    await seedUser(env, 'o3', { role: 'organizer' });
    await seed(env, [['events/e1', eventData({ startsAt: inDays(7) })]]);
  });

  test('an invitee who accepted joins the team', async () => {
    await seed(env, [['events/e1/invitations/o2', {
      eventId: 'e1', userId: 'o2', email: 'o2@example.com', name: 'Name o2', invitedBy: 'o1',
      invitedByName: 'Name o1', eventTitle: 'Flutter Meetup Antananarivo', eventStartsAt: inDays(7),
      status: 'pending', createdAt: Timestamp.now(), respondedAt: null,
    }]]);
    const db = as(env, 'o2').firestore();
    const batch = writeBatch(db);
    batch.update(doc(db, 'events/e1/invitations/o2'), { status: 'accepted', respondedAt: serverTimestamp() });
    batch.update(doc(db, 'events/e1'), { staffIds: ['o2'] });
    await assertSucceeds(batch.commit());
  });

  test('nobody joins a team uninvited', async () => {
    await assertFails(updateDoc(doc(as(env, 'o3').firestore(), 'events/e1'), { staffIds: ['o3'] }));
  });

  test('the invitee lists their invitations across events', async () => {
    await seed(env, [['events/e1/invitations/o2', {
      eventId: 'e1', userId: 'o2', status: 'pending', email: 'o2@example.com',
    }]]);
    const { collectionGroup } = await import('firebase/firestore');
    const mine = query(collectionGroup(as(env, 'o2').firestore(), 'invitations'), where('userId', '==', 'o2'), where('status', '==', 'pending'));
    await assertSucceeds(getDocs(mine));
    const theirs = query(collectionGroup(as(env, 'o3').firestore(), 'invitations'), where('userId', '==', 'o2'));
    await assertFails(getDocs(theirs));
  });

  test('a member leaves; the owner removes', async () => {
    await seed(env, [['events/e1', eventData({ staffIds: ['o2', 'o3'] })]]);
    await assertSucceeds(updateDoc(doc(as(env, 'o2').firestore(), 'events/e1'), { staffIds: ['o3'] }));
    await seed(env, [['events/e1', eventData({ staffIds: ['o2', 'o3'] })]]);
    // A member removes only themself, never a colleague.
    await assertFails(updateDoc(doc(as(env, 'o3').firestore(), 'events/e1'), { staffIds: ['o3'] }));
    await assertSucceeds(updateDoc(doc(as(env, 'o1').firestore(), 'events/e1'), { staffIds: ['o3'] }));
  });
});
