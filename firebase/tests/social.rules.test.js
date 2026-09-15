import { after, beforeEach, describe, test } from 'node:test';

import {
  Timestamp, collection, deleteDoc, doc, getDoc, getDocs, increment, limit, query, setDoc, updateDoc, where, writeBatch,
} from 'firebase/firestore';

import {
  as, assertFails, assertSucceeds, createTestEnv, daysAgo, eventData, inDays, reservationData, reservationId,
  seed, seedAdmin, seedUser, serverTimestamp,
} from './helpers.js';
import { emailKey } from './keys.js';

const env = await createTestEnv();
after(() => env.cleanup());
beforeEach(async () => {
  await env.clearFirestore();
  await seedUser(env, 'o1', { role: 'organizer' });
  await seedUser(env, 'p1');
  await seedUser(env, 'p2');
});

const in30Days = () => Timestamp.fromMillis(Date.now() + 30 * 86_400_000);

describe('following', () => {
  function follow(db, { step = 1 } = {}) {
    const batch = writeBatch(db);
    batch.set(doc(db, 'users/p1/following/o1'), { organizerId: 'o1', createdAt: serverTimestamp() });
    batch.update(doc(db, 'organizers/o1'), { followerCount: increment(step) });
    return batch.commit();
  }

  test('a follow and its counter move together', async () => {
    await assertSucceeds(follow(as(env, 'p1').firestore()));
  });

  test('the counter cannot be skipped nor inflated', async () => {
    const db = as(env, 'p1').firestore();
    await assertFails(setDoc(doc(db, 'users/p1/following/o1'), { organizerId: 'o1', createdAt: serverTimestamp() }));
    await assertFails(follow(db, { step: 50 }));
    await assertFails(updateDoc(doc(db, 'organizers/o1'), { followerCount: increment(1) }));
  });

  test('an unfollow gives exactly one back', async () => {
    await follow(as(env, 'p1').firestore());
    const db = as(env, 'p1').firestore();
    const batch = writeBatch(db);
    batch.delete(doc(db, 'users/p1/following/o1'));
    batch.update(doc(db, 'organizers/o1'), { followerCount: increment(-1) });
    await assertSucceeds(batch.commit());
  });

  test('nobody follows themself', async () => {
    const db = as(env, 'o1').firestore();
    const batch = writeBatch(db);
    batch.set(doc(db, 'users/o1/following/o1'), { organizerId: 'o1', createdAt: serverTimestamp() });
    batch.update(doc(db, 'organizers/o1'), { followerCount: increment(1) });
    await assertFails(batch.commit());
  });
});

describe('reviews', () => {
  beforeEach(() => seed(env, [
    ['events/e1', eventData({ startsAt: daysAgo(1) })],
    [`reservations/${reservationId('e1', 'p1')}`, reservationData({ eventStartsAt: daysAgo(1) })],
  ]));

  function review(db, { userId = 'p1', rating = 4, sum = rating, count = 1 } = {}) {
    const id = reservationId('e1', userId);
    const batch = writeBatch(db);
    batch.set(doc(db, `reviews/${id}`), {
      eventId: 'e1', organizerId: 'o1', authorId: userId, authorName: `Name ${userId}`,
      rating, comment: 'Très bien organisé.', hidden: false, createdAt: serverTimestamp(),
    });
    batch.update(doc(db, 'organizers/o1'), { ratingSum: increment(sum), ratingCount: increment(count), lastReviewId: id });
    return batch.commit();
  }

  test('an attendee reviews after the start, and the rating follows', async () => {
    await assertSucceeds(review(as(env, 'p1').firestore()));
  });

  test('the rating cannot be forged', async () => {
    const db = as(env, 'p1').firestore();
    await assertFails(review(db, { rating: 1, sum: 5 }));
    await assertFails(review(db, { rating: 4, count: 3 }));
  });

  test('a rating cannot be moved without a review', async () => {
    await assertFails(updateDoc(doc(as(env, 'p2').firestore(), 'organizers/o1'), {
      ratingSum: increment(-5), ratingCount: increment(-1), lastReviewId: reservationId('e1', 'p2'),
    }));
  });

  test('someone who did not attend cannot review', async () => {
    await assertFails(review(as(env, 'p2').firestore(), { userId: 'p2' }));
  });

  test('an unverified address cannot review', async () => {
    await assertFails(review(as(env, 'p1', { verified: false }).firestore()));
  });

  test('reviews open only once the event started', async () => {
    await seed(env, [
      ['events/e1', eventData({ startsAt: inDays(2) })],
      [`reservations/${reservationId('e1', 'p1')}`, reservationData({ eventStartsAt: inDays(2) })],
    ]);
    await assertFails(review(as(env, 'p1').firestore()));
  });

  test('hidden reviews stay out of public lists', async () => {
    await seed(env, [[`reviews/${reservationId('e1', 'p1')}`, {
      eventId: 'e1', organizerId: 'o1', authorId: 'p1', authorName: 'Name p1', rating: 1, comment: 'x', hidden: true, createdAt: Timestamp.now(),
    }]]);
    const db = as(env, 'p2').firestore();
    await assertSucceeds(getDocs(query(collection(db, 'reviews'), where('eventId', '==', 'e1'), where('hidden', '==', false), limit(100))));
    await assertFails(getDocs(query(collection(db, 'reviews'), where('eventId', '==', 'e1'), limit(100))));
    await assertFails(getDoc(doc(db, `reviews/${reservationId('e1', 'p1')}`)));
    await assertSucceeds(getDoc(doc(as(env, 'p1').firestore(), `reviews/${reservationId('e1', 'p1')}`)));
  });

  test('moderation hides a review and the rating follows', async () => {
    await seedAdmin(env, 'a1');
    await seed(env, [
      [`reviews/${reservationId('e1', 'p1')}`, {
        eventId: 'e1', organizerId: 'o1', authorId: 'p1', authorName: 'Name p1', rating: 2, comment: 'x', hidden: false, createdAt: Timestamp.now(),
      }],
      ['organizers/o1', { name: 'Name o1', bio: '', memberSince: Timestamp.now(), followerCount: 0, eventCount: 1, ratingSum: 2, ratingCount: 1 }],
    ]);
    const db = as(env, 'a1').firestore();
    const id = reservationId('e1', 'p1');
    const batch = writeBatch(db);
    batch.update(doc(db, `reviews/${id}`), { hidden: true });
    batch.update(doc(db, 'organizers/o1'), { ratingSum: increment(-2), ratingCount: increment(-1), lastReviewId: id });
    await assertSucceeds(batch.commit());
  });

  test('the author deletes their review and the rating follows', async () => {
    await review(as(env, 'p1').firestore());
    const db = as(env, 'p1').firestore();
    const id = reservationId('e1', 'p1');
    const batch = writeBatch(db);
    batch.delete(doc(db, `reviews/${id}`));
    batch.update(doc(db, 'organizers/o1'), { ratingSum: increment(-4), ratingCount: increment(-1), lastReviewId: id });
    await assertSucceeds(batch.commit());
    await assertFails(deleteDoc(doc(as(env, 'p2').firestore(), `reviews/${id}`)));
  });
});

describe('notifications', () => {
  const notice = (overrides) => ({
    title: 'Nouvelle réservation', body: 'Name p1 a réservé.', eventId: 'e1',
    actorId: 'p1', createdAt: serverTimestamp(), readAt: null, expiresAt: in30Days(), ...overrides,
  });

  test('a booking tells the organizer, with the id of that booking', async () => {
    const reservedAt = Timestamp.fromMillis(Date.now() - 1000);
    await seed(env, [
      ['events/e1', eventData()],
      [`reservations/${reservationId('e1', 'p1')}`, reservationData({ reservedAt })],
    ]);
    const db = as(env, 'p1').firestore();
    await assertSucceeds(setDoc(doc(db, `users/o1/notifications/booking_e1_p1_${reservedAt.toMillis()}`), notice({ type: 'booking' })));
  });

  test('a booking notice without a booking is refused', async () => {
    await seed(env, [['events/e1', eventData()]]);
    const db = as(env, 'p1').firestore();
    await assertFails(setDoc(doc(db, 'users/o1/notifications/booking_e1_p1_123'), notice({ type: 'booking' })));
  });

  test('notices cannot be sent to a random person or forged by type', async () => {
    const reservedAt = Timestamp.fromMillis(Date.now() - 1000);
    await seed(env, [
      ['events/e1', eventData()],
      [`reservations/${reservationId('e1', 'p1')}`, reservationData({ reservedAt })],
    ]);
    const db = as(env, 'p1').firestore();
    await assertFails(setDoc(doc(db, `users/p2/notifications/booking_e1_p1_${reservedAt.toMillis()}`), notice({ type: 'booking' })));
    await assertFails(setDoc(doc(db, 'users/p2/notifications/x'), notice({ type: 'eventRemoved' })));
    await assertFails(setDoc(doc(db, 'users/p2/notifications/welcome'), notice({ type: 'welcome' })));
  });

  test('the welcome is written once by the new account itself', async () => {
    const db = as(env, 'p1').firestore();
    await assertSucceeds(setDoc(doc(db, 'users/p1/notifications/welcome'), notice({ type: 'welcome', eventId: null })));
    await assertFails(setDoc(doc(db, 'users/p1/notifications/welcome'), notice({ type: 'welcome', eventId: null })));
  });

  test('the recipient reads, marks read and deletes; nobody else reads', async () => {
    await seed(env, [['users/p1/notifications/n1', {
      type: 'welcome', title: 't', body: 'b', actorId: 'p1', createdAt: Timestamp.now(), readAt: null, expiresAt: in30Days(),
    }]]);
    await assertFails(getDoc(doc(as(env, 'p2').firestore(), 'users/p1/notifications/n1')));
    const db = as(env, 'p1').firestore();
    await assertSucceeds(updateDoc(doc(db, 'users/p1/notifications/n1'), { readAt: serverTimestamp() }));
    await assertFails(updateDoc(doc(db, 'users/p1/notifications/n1'), { title: 'changed' }));
    await assertSucceeds(deleteDoc(doc(db, 'users/p1/notifications/n1')));
  });

  test('the owner invites a co-organizer found by e-mail, and tells them', async () => {
    await seedUser(env, 'o2', { role: 'organizer' });
    await seed(env, [
      ['events/e1', eventData()],
      [`organizerEmails/${emailKey('o2@example.com')}`, { uid: 'o2' }],
    ]);
    const db = as(env, 'o1').firestore();
    await assertSucceeds(getDoc(doc(db, `organizerEmails/${emailKey('O2@example.com')}`)));
    const batch = writeBatch(db);
    batch.set(doc(db, 'events/e1/invitations/o2'), {
      eventId: 'e1', userId: 'o2', email: 'o2@example.com', name: 'Name o2', invitedBy: 'o1',
      invitedByName: 'Name o1', eventTitle: 'Flutter Meetup Antananarivo', eventStartsAt: inDays(7),
      status: 'pending', createdAt: serverTimestamp(), respondedAt: null,
    });
    await assertSucceeds(batch.commit());
    await assertSucceeds(setDoc(doc(db, `users/o2/notifications/staffInvite_e1_o2_${Date.now()}`), notice({
      type: 'staffInvite', title: 'Invitation', body: 'Rejoignez l’équipe.', actorId: 'o1',
    })));
  });

  test('an invitation must match the invitee\'s real address', async () => {
    await seedUser(env, 'o2', { role: 'organizer' });
    await seed(env, [['events/e1', eventData()], [`organizerEmails/${emailKey('o2@example.com')}`, { uid: 'o2' }]]);
    await assertFails(setDoc(doc(as(env, 'o1').firestore(), 'events/e1/invitations/o2'), {
      eventId: 'e1', userId: 'o2', email: 'attacker@example.com', name: 'Name o2', invitedBy: 'o1',
      invitedByName: 'Name o1', eventTitle: 'Flutter Meetup Antananarivo', eventStartsAt: inDays(7),
      status: 'pending', createdAt: serverTimestamp(), respondedAt: null,
    }));
  });
});

describe('reports and moderation', () => {
  function report(db, { reporter = 'p1', type = 'event', target = 'e1', queueStep = 'create' } = {}) {
    const batch = writeBatch(db);
    batch.set(doc(db, `reports/${type}_${target}_${reporter}`), {
      targetType: type, targetId: target, reason: 'spam', details: '', reporterId: reporter, createdAt: serverTimestamp(),
    });
    const entry = doc(db, `moderationQueue/${type}_${target}`);
    if (queueStep === 'create') {
      batch.set(entry, { targetType: type, targetId: target, reportCount: 1, lastReason: 'spam', status: 'open', updatedAt: serverTimestamp() });
    } else if (queueStep === 'increment') {
      batch.update(entry, { reportCount: increment(1), lastReason: 'spam', status: 'open', updatedAt: serverTimestamp() });
    }
    return batch.commit();
  }

  test('a report opens the queue entry; a second reporter counts', async () => {
    await assertSucceeds(report(as(env, 'p1').firestore()));
    await assertSucceeds(report(as(env, 'p2').firestore(), { reporter: 'p2', queueStep: 'increment' }));
  });

  test('one report per person per target', async () => {
    await report(as(env, 'p1').firestore());
    await assertFails(report(as(env, 'p1').firestore(), { queueStep: 'increment' }));
  });

  test('the queue cannot be inflated without reports', async () => {
    await report(as(env, 'p1').firestore());
    await assertFails(updateDoc(doc(as(env, 'p2').firestore(), 'moderationQueue/event_e1'), {
      reportCount: increment(1), status: 'open', updatedAt: serverTimestamp(),
    }));
  });

  test('nobody reports themself; reports are read by moderation only', async () => {
    await assertFails(report(as(env, 'p1').firestore(), { type: 'user', target: 'p1' }));
    await report(as(env, 'p1').firestore());
    await assertFails(getDoc(doc(as(env, 'p2').firestore(), 'reports/event_e1_p1')));
    await seedAdmin(env, 'a1');
    await assertSucceeds(getDoc(doc(as(env, 'a1').firestore(), 'reports/event_e1_p1')));
  });

  test('an administrator decides and records it', async () => {
    await report(as(env, 'p1').firestore());
    await seedAdmin(env, 'a1');
    const db = as(env, 'a1').firestore();
    const batch = writeBatch(db);
    batch.update(doc(db, 'moderationQueue/event_e1'), {
      status: 'dismissed', decision: 'dismiss', decisionNote: '', decidedBy: 'a1', decidedAt: serverTimestamp(), updatedAt: serverTimestamp(),
    });
    batch.set(doc(db, 'moderationQueue/event_e1/decisions/d1'), { action: 'dismiss', note: '', by: 'a1', at: serverTimestamp() });
    await assertSucceeds(batch.commit());
    await assertFails(updateDoc(doc(as(env, 'p1').firestore(), 'moderationQueue/event_e1'), { status: 'resolved' }));
  });
});
