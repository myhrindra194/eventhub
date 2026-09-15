import { after, beforeEach, describe, test } from 'node:test';

import { deleteDoc, doc, getDoc, getDocs, collection, limit, query, setDoc, updateDoc, writeBatch } from 'firebase/firestore';

import {
  as, asAnonymous, assertFails, assertSucceeds, createTestEnv, seed, seedAdmin, seedUser, serverTimestamp,
} from './helpers.js';
import { emailKey } from './keys.js';

const env = await createTestEnv();
after(() => env.cleanup());
beforeEach(() => env.clearFirestore());

function becomeOrganizer(db, uid, { withEmailKey = true, withPage = true } = {}) {
  const batch = writeBatch(db);
  batch.update(doc(db, `users/${uid}`), { role: 'organizer', updatedAt: serverTimestamp() });
  if (withPage) {
    batch.set(doc(db, `organizers/${uid}`), {
      name: `Name ${uid}`, bio: '', memberSince: serverTimestamp(),
      followerCount: 0, eventCount: 0, ratingSum: 0, ratingCount: 0,
    });
  }
  if (withEmailKey) batch.set(doc(db, `organizerEmails/${emailKey(`${uid}@example.com`)}`), { uid });
  return batch.commit();
}

describe('users', () => {
  test('a new account creates its own participant profile', async () => {
    const db = as(env, 'p1').firestore();
    await assertSucceeds(setDoc(doc(db, 'users/p1'), {
      name: 'Soa Rakoto', email: 'p1@example.com', role: 'participant', createdAt: serverTimestamp(),
    }));
  });

  test('nobody signs up straight into the organizer role', async () => {
    const db = as(env, 'p1').firestore();
    await assertFails(setDoc(doc(db, 'users/p1'), {
      name: 'Soa Rakoto', email: 'p1@example.com', role: 'organizer', createdAt: serverTimestamp(),
    }));
  });

  test('the profile email is the one of the token', async () => {
    const db = as(env, 'p1').firestore();
    await assertFails(setDoc(doc(db, 'users/p1'), {
      name: 'Soa Rakoto', email: 'someone-else@example.com', role: 'participant', createdAt: serverTimestamp(),
    }));
  });

  test('profiles are private and never listed', async () => {
    await seedUser(env, 'p1');
    await seedUser(env, 'p2');
    await assertSucceeds(getDoc(doc(as(env, 'p1').firestore(), 'users/p1')));
    await assertFails(getDoc(doc(as(env, 'p2').firestore(), 'users/p1')));
    await assertFails(getDoc(doc(asAnonymous(env).firestore(), 'users/p1')));
    await assertFails(getDocs(query(collection(as(env, 'p1').firestore(), 'users'), limit(5))));
  });

  test('an administrator reads a reported account', async () => {
    await seedUser(env, 'p1');
    await seedAdmin(env, 'a1');
    await assertSucceeds(getDoc(doc(as(env, 'a1').firestore(), 'users/p1')));
  });

  test('the owner edits name and bio, never role or suspension', async () => {
    await seedUser(env, 'p1');
    const db = as(env, 'p1').firestore();
    await assertSucceeds(updateDoc(doc(db, 'users/p1'), { name: 'Soa R.', bio: 'Hello' }));
    await assertFails(updateDoc(doc(db, 'users/p1'), { role: 'organizer' }));
    await assertFails(updateDoc(doc(db, 'users/p1'), { suspended: false }));
  });

  test('a suspended account cannot edit its profile', async () => {
    await seedUser(env, 'p1', { suspended: true });
    await assertFails(updateDoc(doc(as(env, 'p1').firestore(), 'users/p1'), { name: 'New name' }));
  });

  test('only administrators suspend, and never themselves', async () => {
    await seedUser(env, 'p1');
    await seedAdmin(env, 'a1');
    await assertFails(updateDoc(doc(as(env, 'p1').firestore(), 'users/p1'), { suspended: true }));
    await assertSucceeds(updateDoc(doc(as(env, 'a1').firestore(), 'users/p1'), { suspended: true }));
    await assertFails(updateDoc(doc(as(env, 'a1').firestore(), 'users/a1'), { suspended: true }));
  });

  test('the welcome is stamped once', async () => {
    await seedUser(env, 'p1');
    const db = as(env, 'p1').firestore();
    await assertSucceeds(updateDoc(doc(db, 'users/p1'), { welcomedAt: serverTimestamp() }));
    await assertFails(updateDoc(doc(db, 'users/p1'), { welcomedAt: serverTimestamp() }));
  });
});

describe('organizer space', () => {
  test('a verified participant turns the organizer space on in one batch', async () => {
    await seedUser(env, 'p1');
    await assertSucceeds(becomeOrganizer(as(env, 'p1').firestore(), 'p1'));
  });

  test('an unverified address cannot become an organizer', async () => {
    await seedUser(env, 'p1');
    await assertFails(becomeOrganizer(as(env, 'p1', { verified: false }).firestore(), 'p1'));
  });

  test('the role cannot change without the public page', async () => {
    await seedUser(env, 'p1');
    await assertFails(becomeOrganizer(as(env, 'p1').firestore(), 'p1', { withPage: false }));
  });

  test('the page requires the e-mail lookup entry', async () => {
    await seedUser(env, 'p1');
    await assertFails(becomeOrganizer(as(env, 'p1').firestore(), 'p1', { withEmailKey: false }));
  });

  test('a page cannot start with inflated counters', async () => {
    await seedUser(env, 'p1');
    const db = as(env, 'p1').firestore();
    const batch = writeBatch(db);
    batch.update(doc(db, 'users/p1'), { role: 'organizer' });
    batch.set(doc(db, 'organizers/p1'), {
      name: 'Name p1', bio: '', memberSince: serverTimestamp(),
      followerCount: 5000, eventCount: 0, ratingSum: 0, ratingCount: 0,
    });
    batch.set(doc(db, `organizerEmails/${emailKey('p1@example.com')}`), { uid: 'p1' });
    await assertFails(batch.commit());
  });

  test('nobody registers somebody else\'s address', async () => {
    await seedUser(env, 'p1');
    const db = as(env, 'p1').firestore();
    await assertFails(setDoc(doc(db, `organizerEmails/${emailKey('victim@example.com')}`), { uid: 'p1' }));
  });

  test('the organizer space is one way', async () => {
    await seedUser(env, 'o1', { role: 'organizer' });
    await assertFails(updateDoc(doc(as(env, 'o1').firestore(), 'users/o1'), { role: 'participant' }));
  });

  test('the e-mail lookup is a get of one hash, never a list', async () => {
    await seedUser(env, 'o1', { role: 'organizer' });
    await seedUser(env, 'o2', { role: 'organizer' });
    await seed(env, [[`organizerEmails/${emailKey('o2@example.com')}`, { uid: 'o2' }]]);
    const db = as(env, 'o1').firestore();
    await assertSucceeds(getDoc(doc(db, `organizerEmails/${emailKey('o2@example.com')}`)));
    await assertFails(getDocs(query(collection(db, 'organizerEmails'), limit(5))));
    await seedUser(env, 'p1');
    await assertFails(getDoc(doc(as(env, 'p1').firestore(), `organizerEmails/${emailKey('o2@example.com')}`)));
  });
});

describe('private sub-collections', () => {
  test('preferences, favorites and devices belong to their owner', async () => {
    await seedUser(env, 'p1');
    const mine = as(env, 'p1').firestore();
    const other = as(env, 'p2').firestore();
    await assertSucceeds(setDoc(doc(mine, 'users/p1/private/notifications'), { eventReminders: false }));
    await assertFails(setDoc(doc(mine, 'users/p1/private/anything'), { eventReminders: false }));
    await assertFails(getDoc(doc(other, 'users/p1/private/notifications')));
    await assertSucceeds(setDoc(doc(mine, 'users/p1/favorites/e1'), { eventId: 'e1', createdAt: serverTimestamp() }));
    await assertFails(setDoc(doc(other, 'users/p1/favorites/e2'), { eventId: 'e2', createdAt: serverTimestamp() }));
    await assertSucceeds(setDoc(doc(mine, 'users/p1/devices/d1'), { token: 'abc', platform: 'android', updatedAt: serverTimestamp() }));
    await assertSucceeds(deleteDoc(doc(mine, 'users/p1/favorites/e1')));
  });

  test('admins/ is invisible to members and unwritable by anyone', async () => {
    await seedAdmin(env, 'a1');
    await seedUser(env, 'p1');
    await assertFails(getDoc(doc(as(env, 'p1').firestore(), 'admins/a1')));
    await assertFails(setDoc(doc(as(env, 'p1').firestore(), 'admins/p1'), { email: 'p1@example.com' }));
    await assertSucceeds(getDoc(doc(as(env, 'a1').firestore(), 'admins/a1')));
    await assertFails(setDoc(doc(as(env, 'a1').firestore(), 'admins/p1'), { email: 'p1@example.com' }));
  });

  test('a member asks "am I an administrator?" about themself only, and never lists admins', async () => {
    await seedUser(env, 'p1');
    await seedAdmin(env, 'a1');
    const db = as(env, 'p1').firestore();
    // The marker does not exist: the read is allowed and simply finds nothing.
    await assertSucceeds(getDoc(doc(db, 'admins/p1')));
    await assertFails(getDoc(doc(db, 'admins/a1')));
    await assertFails(getDocs(query(collection(db, 'admins'), limit(5))));
    await assertFails(getDoc(doc(asAnonymous(env).firestore(), 'admins/p1')));
    await assertSucceeds(getDocs(query(collection(as(env, 'a1').firestore(), 'admins'), limit(5))));
  });
});
