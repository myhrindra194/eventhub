import assert from 'node:assert/strict';
import { readFileSync, readdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

import { PGlite } from '@electric-sql/pglite';
import { citext } from '@electric-sql/pglite/contrib/citext';
import { pgcrypto } from '@electric-sql/pglite/contrib/pgcrypto';

const HERE = dirname(fileURLToPath(import.meta.url));
const MIGRATIONS = join(HERE, '..', '..', 'migrations');

export const DAY = 24 * 60 * 60 * 1000;

/** A new in-memory database with every migration applied, in order. */
export async function freshDb() {
  const db = new PGlite({ extensions: { citext, pgcrypto } });
  await db.exec(readFileSync(join(HERE, '..', 'stubs.sql'), 'utf8'));
  for (const file of readdirSync(MIGRATIONS).filter((f) => f.endsWith('.sql')).sort()) {
    // pg_net and pg_cron are not built into PGlite: stubs.sql stands in.
    const sql = readFileSync(join(MIGRATIONS, file), 'utf8').replace(
      /create extension if not exists (pg_net|pg_cron)[^;]*;/g,
      '',
    );
    try {
      await db.exec(sql);
    } catch (e) {
      const line = e.position ? sql.slice(0, Number(e.position)).split('\n').length : '?';
      throw new Error(`${file}:${line}: ${e.message}`);
    }
  }
  return db;
}

let sequence = 0;

/** An Auth user, and its profile when [role] is given (written as that user). */
export async function createUser(db, { name, role, email, verified = true }) {
  sequence += 1;
  const address = email ?? `user${sequence}@eventhub.test`;
  const {
    rows: [user],
  } = await db.query(
    'insert into auth.users (email, email_confirmed_at) values ($1, $2) returning id',
    [address, verified ? new Date().toISOString() : null],
  );
  if (role) {
    await asUser(db, user.id, (tx) =>
      tx.query(
        'insert into public.profiles (id, name, email, role) values ($1, $2, $3, $4)',
        [user.id, name, 'forged@elsewhere.test', role],
      ),
    );
  }
  return user.id;
}

/** Runs [fn] in a transaction as the signed-in user [uid], RLS applied. */
export function asUser(db, uid, fn, { method = 'POST' } = {}) {
  return db.transaction(async (tx) => {
    await tx.query(
      `select set_config('request.jwt.claim.sub', $1, true),
              set_config('request.jwt.claims', $2, true),
              set_config('request.method', $3, true)`,
      [uid, JSON.stringify({ sub: uid, role: 'authenticated' }), method],
    );
    await tx.exec('set local role authenticated');
    return fn(tx);
  });
}

/** Runs [fn] as an anonymous API caller. */
export function asAnon(db, fn) {
  return db.transaction(async (tx) => {
    await tx.exec('set local role anon');
    return fn(tx);
  });
}

/** Runs [fn] with the service role, as the Edge Functions do. */
export function asService(db, fn) {
  return db.transaction(async (tx) => {
    await tx.exec('set local role service_role');
    return fn(tx);
  });
}

/** `public.<name>(p_a => …)`, the result as JSON (scalar, composite or jsonb). */
export async function rpc(tx, name, args = {}) {
  const keys = Object.keys(args);
  const params = keys.map((k, i) => `${k} => $${i + 1}`).join(', ');
  const { rows } = await tx.query(
    `select to_jsonb(r) as result from public.${name}(${params}) r`,
    keys.map((k) => normalize(args[k])),
  );
  return rows[0]?.result;
}

/** Same as [rpc] for functions returning void. */
export async function call(tx, name, args = {}) {
  const keys = Object.keys(args);
  const params = keys.map((k, i) => `${k} => $${i + 1}`).join(', ');
  await tx.query(`select 1 from public.${name}(${params}) r`, keys.map((k) => normalize(args[k])));
}

function normalize(value) {
  if (value !== null && typeof value === 'object' && !(value instanceof Date)) {
    return JSON.stringify(value);
  }
  return value;
}

/**
 * Awaits a rejection and checks it: [status] is the HTTP status carried by
 * the SQLSTATE (`PT409`), [rule] the `hint` the app maps to BusinessRule,
 * [code] a raw SQLSTATE (`42501` permission denied, `23505` unique).
 */
export async function rejects(promise, { status, rule, code } = {}) {
  try {
    await promise;
  } catch (e) {
    if (status !== undefined) assert.equal(e.code, `PT${status}`, e.message);
    if (rule !== undefined) assert.equal(e.hint, rule, e.message);
    if (code !== undefined) assert.equal(e.code, code, e.message);
    return e;
  }
  assert.fail('expected the call to be rejected');
}

export function inDays(days) {
  return new Date(Date.now() + days * DAY).toISOString();
}

/** Publishes an event as [organizer]; returns its id. */
export function publish(db, organizer, overrides = {}) {
  return asUser(db, organizer, (tx) =>
    rpc(tx, 'save_event', {
      p_event: {
        title: 'Flutter Meetup',
        description: 'Talks and pizza.',
        category: 'meetup',
        starts_at: inDays(3),
        location: 'Antananarivo',
        capacity: 2,
        ...overrides,
      },
    }),
  );
}

/** Superuser read, RLS bypassed. */
export async function one(db, sql, params = []) {
  const { rows } = await db.query(sql, params);
  return rows[0];
}

export async function all(db, sql, params = []) {
  const { rows } = await db.query(sql, params);
  return rows;
}
