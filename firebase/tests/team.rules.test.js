import { after, beforeEach, describe, test } from 'node:test';

import {
  Timestamp, arrayRemove, arrayUnion, deleteDoc, doc, getDocs, collection, limit, query, setDoc, updateDoc, where, writeBatch,
} from 'firebase/firestore';

import {
  as, assertFails, assertSucceeds, createTestEnv, eventData, inDays, reservationData, reservationId,
  seed, seedAdmin, seedUser, serverTimestamp,
} from './helpers.js';

const env = await createTestEnv();
after(() => env.cleanup());
beforeEach(async () => {
  await env.clearFirestore();
  await seedUser(env, 'o1', { role: 'organizer' });
  await seedUser(env, 'o2', { role: 'organizer' });
  await seedUser(env, 'p1');
});

/** L’invitation écrite par le propriétaire (forme : voir social.rules.test.js). */
const invitation = (overrides = {}) => ({
  eventId: 'e1', userId: 'o2', email: 'o2@example.com', name: 'Name o2', invitedBy: 'o1',
  invitedByName: 'Name o1', eventTitle: 'Flutter Meetup Antananarivo', eventStartsAt: inDays(7),
  status: 'pending', createdAt: Timestamp.now(), respondedAt: null, ...overrides,
});

describe('joining a team', () => {
  beforeEach(() => seed(env, [
    ['events/e1', eventData()],
    ['events/e1/invitations/o2', invitation()],
  ]));

  /** Répondre et rejoindre voyagent ensemble, ou pas du tout. */
  function accept(db, { uid = 'o2', both = true } = {}) {
    const batch = writeBatch(db);
    batch.update(doc(db, `events/e1/invitations/${uid}`), { status: 'accepted', respondedAt: serverTimestamp() });
    if (both) batch.update(doc(db, 'events/e1'), { staffIds: arrayUnion(uid) });
    return batch.commit();
  }

  test('the invitee accepts and joins the team in one commit', async () => {
    await assertSucceeds(accept(as(env, 'o2').firestore()));
  });

  test('declining answers without joining', async () => {
    const db = as(env, 'o2').firestore();
    await assertSucceeds(updateDoc(doc(db, 'events/e1/invitations/o2'), {
      status: 'declined', respondedAt: serverTimestamp(),
    }));
  });

  test('nobody adds themself to a team without an accepted invitation', async () => {
    await assertFails(updateDoc(doc(as(env, 'o2').firestore(), 'events/e1'), { staffIds: arrayUnion('o2') }));
    await seedUser(env, 'o3', { role: 'organizer' });
    await assertFails(updateDoc(doc(as(env, 'o3').firestore(), 'events/e1'), { staffIds: arrayUnion('o3') }));
  });

  test('nobody answers an invitation addressed to someone else', async () => {
    await assertFails(accept(as(env, 'p1').firestore(), { uid: 'o2' }));
  });

  test('an answered invitation cannot be answered again', async () => {
    await accept(as(env, 'o2').firestore());
    await assertFails(updateDoc(doc(as(env, 'o2').firestore(), 'events/e1/invitations/o2'), {
      status: 'declined', respondedAt: serverTimestamp(),
    }));
  });

  test('a suspended account cannot join a team', async () => {
    await seedUser(env, 'o2', { role: 'organizer', suspended: true });
    await assertFails(accept(as(env, 'o2').firestore()));
  });

  test('the invitee finds their own invitations across events', async () => {
    const db = as(env, 'o2').firestore();
    await assertSucceeds(getDocs(query(
      collection(db, 'invitations'), where('userId', '==', 'o2'), where('status', '==', 'pending'), limit(50),
    )));
    // …et uniquement les siennes.
    await assertFails(getDocs(query(
      collection(db, 'invitations'), where('userId', '==', 'p1'), where('status', '==', 'pending'), limit(50),
    )));
  });
});

describe('leaving a team', () => {
  beforeEach(() => seed(env, [
    ['events/e1', eventData({ staffIds: ['o2'] })],
    ['events/e1/invitations/o2', invitation({ status: 'accepted', respondedAt: Timestamp.now() })],
  ]));

  test('a member leaves, and the owner removes a member', async () => {
    await assertSucceeds(updateDoc(doc(as(env, 'o2').firestore(), 'events/e1'), { staffIds: arrayRemove('o2') }));
    await seed(env, [['events/e1', eventData({ staffIds: ['o2'] })]]);
    await assertSucceeds(updateDoc(doc(as(env, 'o1').firestore(), 'events/e1'), { staffIds: arrayRemove('o2') }));
  });

  test('a stranger removes nobody', async () => {
    await assertFails(updateDoc(doc(as(env, 'p1').firestore(), 'events/e1'), { staffIds: arrayRemove('o2') }));
  });

  test('the owner cancels a pending invitation; the invitee may refuse it away', async () => {
    await seed(env, [['events/e1/invitations/o2', invitation()]]);
    await assertFails(deleteDoc(doc(as(env, 'p1').firestore(), 'events/e1/invitations/o2')));
    await assertSucceeds(deleteDoc(doc(as(env, 'o1').firestore(), 'events/e1/invitations/o2')));
  });
});

describe('moderation decisions', () => {
  beforeEach(async () => {
    await seedAdmin(env, 'a1');
    await seed(env, [
      ['events/e1', eventData()],
      [`reservations/${reservationId('e1', 'p1')}`, reservationData()],
      ['moderationQueue/event_e1', {
        targetType: 'event', targetId: 'e1', reportCount: 2, lastReason: 'fraud',
        status: 'open', updatedAt: Timestamp.now(),
      }],
      ['moderationQueue/user_p1', {
        targetType: 'user', targetId: 'p1', reportCount: 1, lastReason: 'harassment',
        status: 'open', updatedAt: Timestamp.now(),
      }],
    ]);
  });

  test('an administrator cancels every seat and deletes the event', async () => {
    const db = as(env, 'a1').firestore();
    const batch = writeBatch(db);
    batch.update(doc(db, `reservations/${reservationId('e1', 'p1')}`), {
      status: 'cancelled', cancelledAt: Timestamp.now(), cancelledBy: 'moderation',
    });
    batch.set(doc(db, `users/p1/notifications/eventRemoved_a1_${Date.now()}`), {
      type: 'eventRemoved', title: 'Événement retiré', body: 'Votre réservation est annulée.',
      eventId: 'e1', reservationId: null, actorId: 'a1', createdAt: serverTimestamp(),
      readAt: null, expiresAt: inDays(30),
    });
    batch.delete(doc(db, 'events/e1'));
    batch.update(doc(db, 'moderationQueue/event_e1'), {
      status: 'resolved', decision: 'removeEvent', decisionNote: 'Faux événement.',
      decidedBy: 'a1', decidedAt: serverTimestamp(), updatedAt: serverTimestamp(),
    });
    await assertSucceeds(batch.commit());
  });

  test('nobody but moderation cancels somebody else\'s seat', async () => {
    await assertFails(updateDoc(doc(as(env, 'o1').firestore(), `reservations/${reservationId('e1', 'p1')}`), {
      status: 'cancelled', cancelledAt: Timestamp.now(), cancelledBy: 'moderation',
    }));
  });

  test('a suspension is written on the profile and mirrored on the public page', async () => {
    await seed(env, [['organizers/p1', {
      name: 'Name p1', bio: '', memberSince: Timestamp.now(),
      followerCount: 0, eventCount: 0, ratingSum: 0, ratingCount: 0,
    }]]);
    const db = as(env, 'a1').firestore();
    const batch = writeBatch(db);
    batch.update(doc(db, 'users/p1'), { suspended: true });
    batch.update(doc(db, 'organizers/p1'), { suspended: true });
    batch.set(doc(db, `users/p1/notifications/accountSuspended_a1_${Date.now()}`), {
      type: 'accountSuspended', title: 'Compte suspendu', body: 'Décision de la modération.',
      eventId: null, reservationId: null, actorId: 'a1', createdAt: serverTimestamp(),
      readAt: null, expiresAt: inDays(30),
    });
    batch.update(doc(db, 'moderationQueue/user_p1'), {
      status: 'resolved', decision: 'suspend', decisionNote: 'Harcèlement.',
      decidedBy: 'a1', decidedAt: serverTimestamp(), updatedAt: serverTimestamp(),
    });
    await assertSucceeds(batch.commit());
  });

  test('a suspended account reads but writes nothing', async () => {
    await seedUser(env, 'p1', { suspended: true });
    await seed(env, [['events/e2', eventData({ organizerId: 'o1' })]]);
    const db = as(env, 'p1').firestore();
    await assertFails(updateDoc(doc(db, 'users/p1'), { name: 'Nouveau nom' }));
    const batch = writeBatch(db);
    batch.set(doc(db, `reservations/${reservationId('e2', 'p1')}`), reservationData({ eventId: 'e2' }));
    batch.update(doc(db, 'events/e2'), { availablePlaces: 9 });
    await assertFails(batch.commit());
  });

  test('a moderation notice can only be written by an administrator', async () => {
    // Même avis, même destinataire : seul l’auteur diffère.
    await assertFails(moderationNotice(as(env, 'o1').firestore(), 'o1'));
    await assertSucceeds(moderationNotice(as(env, 'a1').firestore(), 'a1'));
  });
});

/** L’avis qu’une décision laisse à la personne concernée. */
function moderationNotice(db, actorId) {
  return setDoc(doc(db, `users/p1/notifications/reviewRestored_${actorId}_${Date.now()}`), {
    type: 'reviewRestored', title: 'Votre avis est rétabli', body: 'Après vérification.',
    eventId: 'e1', reservationId: null, actorId,
    createdAt: serverTimestamp(), readAt: null, expiresAt: inDays(30),
  });
}
