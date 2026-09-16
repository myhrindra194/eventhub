import { after, beforeEach, describe, test } from 'node:test';

import {
  Timestamp, collection, doc, getDoc, getDocs, limit, query, runTransaction, setDoc, updateDoc, where, writeBatch,
} from 'firebase/firestore';

import {
  as, assertFails, assertSucceeds, attendeeKey, createTestEnv, daysAgo, eventData, reservationData,
  reservationId, seed, seedAdmin, seedUser, serverTimestamp,
} from './helpers.js';

const env = await createTestEnv();
after(() => env.cleanup());
beforeEach(async () => {
  await env.clearFirestore();
  await seedUser(env, 'o1', { role: 'organizer' });
  await seedUser(env, 'p1');
  await seedUser(env, 'p2');
});

/** Ce que fait l’app : une transaction lit l’événement et prend la place. */
function book(db, { eventId = 'e1', userId = 'p1', seatDelta = -1, tierId, overrides = {} } = {}) {
  return runTransaction(db, async (tx) => {
    const eventRef = doc(db, `events/${eventId}`);
    const event = (await tx.get(eventRef)).data();
    const update = { availablePlaces: event.availablePlaces + seatDelta };
    if (tierId) update[`tiers.${tierId}.available`] = event.tiers[tierId].available + seatDelta;
    tx.update(eventRef, update);
    tx.set(doc(db, `reservations/${reservationId(eventId, userId)}`), reservationData({
      eventId, userId, userName: `Name ${userId}`, userEmail: `${userId}@example.com`,
      eventStartsAt: event.startsAt,
      ...(tierId ? { tierId, tierName: event.tiers[tierId].name } : {}),
      ...overrides,
    }));
  });
}

function cancel(db, { eventId = 'e1', userId = 'p1', seatDelta = 1 } = {}) {
  return runTransaction(db, async (tx) => {
    const eventRef = doc(db, `events/${eventId}`);
    const event = (await tx.get(eventRef)).data();
    tx.update(eventRef, { availablePlaces: event.availablePlaces + seatDelta });
    tx.update(doc(db, `reservations/${reservationId(eventId, userId)}`), {
      status: 'cancelled', cancelledAt: Timestamp.now(), cancelledBy: userId,
    });
  });
}

describe('booking a free seat', () => {
  beforeEach(() => seed(env, [['events/e1', eventData({ capacity: 2, availablePlaces: 2 })]]));

  test('a participant books and the seat is taken atomically', async () => {
    await assertSucceeds(book(as(env, 'p1').firestore()));
  });

  test('an organizer account does not book: the two roles are exclusive', async () => {
    await seedUser(env, 'o2', { role: 'organizer' });
    await assertFails(book(as(env, 'o2').firestore(), { userId: 'o2' }));
  });

  test('a booking that does not take the seat is refused', async () => {
    await assertFails(book(as(env, 'p1').firestore(), { seatDelta: 0 }));
  });

  test('taking two seats for one booking is refused', async () => {
    await assertFails(book(as(env, 'p1').firestore(), { seatDelta: -2 }));
  });

  test('a full event cannot be overbooked', async () => {
    await seed(env, [['events/e1', eventData({ capacity: 2, availablePlaces: 0 })]]);
    await assertFails(book(as(env, 'p1').firestore()));
  });

  test('an event that started cannot be booked', async () => {
    await seed(env, [['events/e1', eventData({ startsAt: daysAgo(1) })]]);
    await assertFails(book(as(env, 'p1').firestore()));
  });

  test('nobody books for somebody else', async () => {
    await assertFails(book(as(env, 'p2').firestore(), { userId: 'p1' }));
  });

  test('the event team does not book its own event', async () => {
    await assertFails(book(as(env, 'o1').firestore(), { userId: 'o1' }));
  });

  test('a suspended account cannot book', async () => {
    await seedUser(env, 'p3', { suspended: true });
    await assertFails(book(as(env, 'p3').firestore(), { userId: 'p3' }));
  });

  test('the ticket copies the real event, not a forged title', async () => {
    await assertFails(book(as(env, 'p1').firestore(), { overrides: { eventTitle: 'VIP backstage' } }));
  });

  test('a seat is never marked paid without a payment server', async () => {
    await assertFails(book(as(env, 'p1').firestore(), { overrides: { pricePaid: 5000 } }));
  });

  test('the seat counter cannot be moved without a reservation', async () => {
    await assertFails(updateDoc(doc(as(env, 'p1').firestore(), 'events/e1'), { availablePlaces: 1 }));
  });
});

describe('ticket types', () => {
  beforeEach(() => seed(env, [['events/e1', eventData({
    capacity: 4, availablePlaces: 4, currency: 'EUR',
    tiers: {
      tfree: { name: 'Standard', description: '', price: 0, capacity: 2, available: 2, order: 0 },
      tvip: { name: 'VIP', description: '', price: 2500, capacity: 2, available: 2, order: 1 },
    },
  })]]));

  test('a free ticket type is booked, both counters move', async () => {
    await assertSucceeds(book(as(env, 'p1').firestore(), { tierId: 'tfree' }));
  });

  test('a paid ticket type is not bookable without payment', async () => {
    await assertFails(book(as(env, 'p1').firestore(), { tierId: 'tvip' }));
  });

  test('an event with types requires one', async () => {
    await assertFails(book(as(env, 'p1').firestore()));
  });
});

describe('cancelling', () => {
  beforeEach(() => seed(env, [
    ['events/e1', eventData({ capacity: 2, availablePlaces: 1 })],
    [`reservations/${reservationId('e1', 'p1')}`, reservationData()],
  ]));

  test('the holder cancels and gives the seat back', async () => {
    await assertSucceeds(cancel(as(env, 'p1').firestore()));
  });

  test('a cancellation must release exactly one seat', async () => {
    await assertFails(cancel(as(env, 'p1').firestore(), { seatDelta: 0 }));
    await assertFails(cancel(as(env, 'p1').firestore(), { seatDelta: 2 }));
  });

  test('nobody cancels somebody else\'s seat', async () => {
    await assertFails(cancel(as(env, 'p2').firestore(), { userId: 'p1' }));
  });

  test('a cancelled ticket is booked again on the same id', async () => {
    await assertSucceeds(cancel(as(env, 'p1').firestore()));
    const db = as(env, 'p1').firestore();
    await assertSucceeds(runTransaction(db, async (tx) => {
      const eventRef = doc(db, 'events/e1');
      const event = (await tx.get(eventRef)).data();
      tx.update(eventRef, { availablePlaces: event.availablePlaces - 1 });
      tx.set(doc(db, `reservations/${reservationId('e1', 'p1')}`), reservationData({ eventStartsAt: event.startsAt }));
    }));
  });

  test('history is never deleted', async () => {
    const { deleteDoc } = await import('firebase/firestore');
    await assertFails(deleteDoc(doc(as(env, 'p1').firestore(), `reservations/${reservationId('e1', 'p1')}`)));
  });
});

describe('reading tickets', () => {
  beforeEach(() => seed(env, [
    ['events/e1', eventData({ capacity: 2, availablePlaces: 1, staffIds: ['o2'] })],
    [`reservations/${reservationId('e1', 'p1')}`, reservationData()],
  ]));

  test('the holder, the owner and the team read the ticket; others do not', async () => {
    await seedUser(env, 'o2', { role: 'organizer' });
    const id = `reservations/${reservationId('e1', 'p1')}`;
    await assertSucceeds(getDoc(doc(as(env, 'p1').firestore(), id)));
    await assertSucceeds(getDoc(doc(as(env, 'o1').firestore(), id)));
    await assertSucceeds(getDoc(doc(as(env, 'o2').firestore(), id)));
    await assertFails(getDoc(doc(as(env, 'p2').firestore(), id)));
  });

  test('"have I booked?" probes only one\'s own seat', async () => {
    await assertSucceeds(getDoc(doc(as(env, 'p2').firestore(), `reservations/${reservationId('e1', 'p2')}`)));
    await assertFails(getDoc(doc(as(env, 'p2').firestore(), `reservations/${reservationId('e9', 'p1')}`)));
  });

  test('lists pin the reader: own tickets, own events, the team\'s event', async () => {
    const p1 = as(env, 'p1').firestore();
    await assertSucceeds(getDocs(query(collection(p1, 'reservations'), where('userId', '==', 'p1'), limit(50))));
    await assertFails(getDocs(query(collection(p1, 'reservations'), where('userId', '==', 'p2'), limit(50))));
    const o1 = as(env, 'o1').firestore();
    await assertSucceeds(getDocs(query(collection(o1, 'reservations'), where('organizerId', '==', 'o1'), limit(50))));
    await seedUser(env, 'o2', { role: 'organizer' });
    const o2 = as(env, 'o2').firestore();
    await assertSucceeds(getDocs(query(collection(o2, 'reservations'), where('eventId', '==', 'e1'), limit(50))));
    await assertFails(getDocs(query(collection(o2, 'reservations'), where('organizerId', '==', 'o1'), limit(50))));
  });
});

describe('door, attendees and account deletion', () => {
  beforeEach(() => seed(env, [
    ['events/e1', eventData({ capacity: 2, availablePlaces: 1, staffIds: ['o2'] })],
    [`reservations/${reservationId('e1', 'p1')}`, reservationData()],
  ]));

  test('the team checks a confirmed ticket in, once', async () => {
    await seedUser(env, 'o2', { role: 'organizer' });
    const id = reservationId('e1', 'p1');
    const db = as(env, 'o2').firestore();
    await assertSucceeds(setDoc(doc(db, `events/e1/checkins/${id}`), { reservationId: id, scannedBy: 'o2', scannedAt: serverTimestamp() }));
    await assertFails(setDoc(doc(db, `events/e1/checkins/${id}`), { reservationId: id, scannedBy: 'o2', scannedAt: serverTimestamp() }));
    await assertFails(setDoc(doc(as(env, 'p1').firestore(), `events/e1/checkins/${id}`), { reservationId: id, scannedBy: 'p1', scannedAt: serverTimestamp() }));
  });

  test('an attendee lists themself under a hashed key, with a short name', async () => {
    const db = as(env, 'p1').firestore();
    await assertSucceeds(setDoc(doc(db, `events/e1/attendees/${attendeeKey('p1')}`), { name: 'Name P.', createdAt: serverTimestamp() }));
    await assertFails(setDoc(doc(as(env, 'p2').firestore(), `events/e1/attendees/${attendeeKey('p2')}`), { name: 'Ghost', createdAt: serverTimestamp() }));
  });

  test('a deleted account leaves an anonymised ticket', async () => {
    const db = as(env, 'p1').firestore();
    await assertSucceeds(updateDoc(doc(db, `reservations/${reservationId('e1', 'p1')}`), {
      userId: '', userName: 'Compte supprimé', userEmail: 'supprime@eventhub.invalid',
    }));
  });

  test('moderation cancels every seat of a removed event', async () => {
    await seedAdmin(env, 'a1');
    const db = as(env, 'a1').firestore();
    await assertSucceeds(updateDoc(doc(db, `reservations/${reservationId('e1', 'p1')}`), {
      status: 'cancelled', cancelledAt: Timestamp.now(), cancelledBy: 'moderation',
    }));
  });
});

describe('waiting list', () => {
  test('join only a full, upcoming event; the next seat is announced', async () => {
    await seed(env, [['events/e1', eventData({ capacity: 1, availablePlaces: 0 })]]);
    const p2 = as(env, 'p2').firestore();
    await assertSucceeds(setDoc(doc(p2, 'events/e1/waitlist/p2'), { userId: 'p2', createdAt: serverTimestamp() }));
    await assertFails(setDoc(doc(p2, 'events/e1/waitlist/p1'), { userId: 'p1', createdAt: serverTimestamp() }));

    await seed(env, [['events/e2', eventData({ capacity: 1, availablePlaces: 1 })]]);
    await assertFails(setDoc(doc(p2, 'events/e2/waitlist/p2'), { userId: 'p2', createdAt: serverTimestamp() }));
  });

  test('the person who cancelled tells the head of the queue', async () => {
    await seed(env, [
      ['events/e1', eventData({ capacity: 1, availablePlaces: 1 })],
      [`reservations/${reservationId('e1', 'p1')}`, reservationData({ status: 'cancelled', cancelledAt: Timestamp.now(), cancelledBy: 'p1' })],
      ['events/e1/waitlist/p2', { userId: 'p2', createdAt: Timestamp.now(), notifiedAt: null }],
    ]);
    const db = as(env, 'p1').firestore();
    const head = await assertSucceeds(getDocs(query(collection(db, 'events/e1/waitlist'), where('notifiedAt', '==', null), limit(1))));
    if (head.size !== 1) throw new Error('queue head not visible');
    const batch = writeBatch(db);
    batch.update(doc(db, 'events/e1/waitlist/p2'), { notifiedAt: serverTimestamp() });
    batch.set(doc(db, 'users/p2/notifications/waitlist_e1_p2_p1'), {
      type: 'waitlist', title: 'Une place s’est libérée', body: 'Réservez vite.', eventId: 'e1',
      actorId: 'p1', createdAt: serverTimestamp(), readAt: null, expiresAt: Timestamp.fromMillis(Date.now() + 30 * 86_400_000),
    });
    await assertSucceeds(batch.commit());
  });
});
