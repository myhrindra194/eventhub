import { after, before, beforeEach, describe, it } from 'node:test';

import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { ref, uploadBytes } from 'firebase/storage';

import {
  asAnonymous,
  asOrganizer,
  asParticipant,
  createTestEnv,
} from './helpers.js';

/**
 * Cloud Storage security-rules suite.
 *
 * Reminder of what is being tested: these rules gate the **authenticated
 * Storage API**. They do not gate a tokenised download URL — see
 * `docs/SECURITY.md` §8. So the assertions below are all about who may write
 * what, and about the two properties that actually stop an attack: the
 * content-type whitelist (no SVG) and the size ceiling.
 */

let env;

/** Deterministic payloads; only the length and the declared type matter. */
const bytes = (size) => new Uint8Array(size).fill(0x42);

const jpeg = { contentType: 'image/jpeg' };
const png = { contentType: 'image/png' };
const svg = { contentType: 'image/svg+xml' };

before(async () => {
  env = await createTestEnv();

  // Warm-up. The Storage emulator loads the ruleset lazily on the first
  // request, and that first request can race it — which showed up exactly
  // once, as the first assertion of the suite failing while the identical
  // one later passed. Burning one throwaway request here makes the suite
  // deterministic instead of intermittently red in CI.
  await uploadBytes(
    ref(env.unauthenticatedContext().storage(), 'warmup/probe.jpg'),
    bytes(1),
    jpeg,
  ).catch(() => {});
});

after(async () => {
  await env?.cleanup();
});

beforeEach(async () => {
  await env.clearStorage();
});

describe('event covers', () => {
  it('lets an organizer upload into their own prefix', async () => {
    const storage = asOrganizer(env, 'o1').storage();
    await assertSucceeds(
      uploadBytes(ref(storage, 'events/o1/cover.jpg'), bytes(1024), jpeg),
    );
  });

  it('refuses an upload into somebody else’s prefix', async () => {
    const storage = asOrganizer(env, 'o2').storage();
    await assertFails(
      uploadBytes(ref(storage, 'events/o1/cover.jpg'), bytes(1024), jpeg),
    );
  });

  it('refuses an anonymous upload', async () => {
    const storage = asAnonymous(env).storage();
    await assertFails(
      uploadBytes(ref(storage, 'events/o1/cover.jpg'), bytes(1024), jpeg),
    );
  });

  it('refuses SVG — it is executable markup, not a picture', async () => {
    const storage = asOrganizer(env, 'o1').storage();
    await assertFails(
      uploadBytes(ref(storage, 'events/o1/payload.svg'), bytes(512), svg),
    );
  });

  it('refuses a non-image content type', async () => {
    const storage = asOrganizer(env, 'o1').storage();
    await assertFails(
      uploadBytes(ref(storage, 'events/o1/script.txt'), bytes(512), {
        contentType: 'text/html',
      }),
    );
  });

  it('refuses a file above the 5 MB ceiling', async () => {
    const storage = asOrganizer(env, 'o1').storage();
    await assertFails(
      uploadBytes(
        ref(storage, 'events/o1/huge.jpg'),
        bytes(5 * 1024 * 1024 + 1),
        jpeg,
      ),
    );
  });

  it('accepts a file just under the ceiling', async () => {
    const storage = asOrganizer(env, 'o1').storage();
    await assertSucceeds(
      uploadBytes(
        ref(storage, 'events/o1/big.jpg'),
        bytes(5 * 1024 * 1024 - 1024),
        jpeg,
      ),
    );
  });

  it('refuses an empty file', async () => {
    const storage = asOrganizer(env, 'o1').storage();
    await assertFails(
      uploadBytes(ref(storage, 'events/o1/empty.jpg'), bytes(0), jpeg),
    );
  });

  it('refuses a traversal-flavoured file name', async () => {
    const storage = asOrganizer(env, 'o1').storage();
    await assertFails(
      uploadBytes(ref(storage, 'events/o1/..evil.jpg'), bytes(512), jpeg),
    );
  });
});

describe('avatars', () => {
  it('lets a user upload their own avatar', async () => {
    const storage = asParticipant(env, 'p1').storage();
    await assertSucceeds(
      uploadBytes(ref(storage, 'avatars/p1/me.png'), bytes(4096), png),
    );
  });

  it('refuses uploading an avatar for somebody else', async () => {
    const storage = asParticipant(env, 'p1').storage();
    await assertFails(
      uploadBytes(ref(storage, 'avatars/p2/me.png'), bytes(4096), png),
    );
  });

  it('applies a tighter 2 MB ceiling than event covers', async () => {
    const storage = asParticipant(env, 'p1').storage();
    await assertFails(
      uploadBytes(
        ref(storage, 'avatars/p1/huge.png'),
        bytes(2 * 1024 * 1024 + 1),
        png,
      ),
    );
  });
});

describe('closed prefixes', () => {
  it('keeps private/ unreachable from any client', async () => {
    const storage = asOrganizer(env, 'o1').storage();
    await assertFails(
      uploadBytes(ref(storage, 'private/exports/list.csv'), bytes(64), {
        contentType: 'text/csv',
      }),
    );
  });

  it('denies any prefix nobody wrote a rule for', async () => {
    const storage = asOrganizer(env, 'o1').storage();
    await assertFails(
      uploadBytes(ref(storage, 'random/whatever.jpg'), bytes(64), jpeg),
    );
  });
});
