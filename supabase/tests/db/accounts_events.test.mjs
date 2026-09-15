import assert from 'node:assert/strict';
import { before, describe, it } from 'node:test';

import {
  all, asAnon, asUser, call, createUser, freshDb, inDays, one, publish, rejects, rpc,
} from './helpers.mjs';

describe('accounts', () => {
  let db;
  before(async () => {
    db = await freshDb();
  });

  it('takes the email from Auth, creates preferences, a public page and the role claim', async () => {
    const uid = await createUser(db, { name: 'Mirindra Rabe', role: 'organizer', email: 'mirindra@eventhub.test' });
    const profile = await one(db, 'select email::text, role from public.profiles where id = $1', [uid]);
    assert.equal(profile.email, 'mirindra@eventhub.test');
    assert.ok(await one(db, 'select 1 from public.notification_preferences where user_id = $1', [uid]));
    assert.equal((await one(db, 'select name from public.organizers where id = $1', [uid])).name, 'Mirindra Rabe');
    const meta = await one(db, 'select raw_app_meta_data from auth.users where id = $1', [uid]);
    assert.equal(meta.raw_app_meta_data.role, 'organizer');
  });

  it('creates a participant profile with the account, whatever the sign-up metadata claim', async () => {
    const insert = (email, metadata) => one(db,
      'insert into auth.users (email, raw_user_meta_data) values ($1, $2) returning id', [email, JSON.stringify(metadata)]);
    const claimed = await insert('signup-org@eventhub.test', { name: '  Rova  Andria ', role: 'organizer' });
    assert.deepEqual(
      await one(db, 'select name, role from public.profiles where id = $1', [claimed.id]),
      { name: 'Rova  Andria', role: 'participant' },
    );
    assert.equal(await one(db, 'select 1 from public.organizers where id = $1', [claimed.id]), undefined);

    const google = await insert('signup-google@eventhub.test', { full_name: 'Hery Randria' });
    assert.equal((await one(db, 'select role from public.profiles where id = $1', [google.id])).role, 'participant');

    for (const metadata of [{ name: 'X' }, {}]) {
      const { id } = await insert(`signup-${Math.random()}@eventhub.test`, metadata);
      assert.equal(await one(db, 'select 1 from public.profiles where id = $1', [id]), undefined);
    }
  });

  it('turns the organizer space on for a verified account, once, and never back', async () => {
    const fresh = (await one(db, "insert into auth.users (email, email_confirmed_at) values ('forced-role@eventhub.test', now()) returning id")).id;
    await asUser(db, fresh, (tx) => tx.query(
      "insert into public.profiles (id, name, email, role) values ($1, 'Forced Role', 'x@elsewhere.test', 'organizer')", [fresh]));
    assert.equal((await one(db, 'select role from public.profiles where id = $1', [fresh])).role, 'participant', 'a client cannot insert an organizer');

    const unverified = await createUser(db, { name: 'Pas Confirmé', role: 'participant', verified: false });
    await rejects(asUser(db, unverified, (tx) => rpc(tx, 'become_organizer')), { status: 403, rule: 'emailNotVerified' });

    assert.deepEqual(await asUser(db, fresh, (tx) => rpc(tx, 'become_organizer')), { organizer: true, changed: true });
    assert.deepEqual(await asUser(db, fresh, (tx) => rpc(tx, 'become_organizer')), { organizer: true, changed: false });
    assert.equal((await one(db, 'select name from public.organizers where id = $1', [fresh])).name, 'Forced Role');
    assert.equal((await one(db, 'select raw_app_meta_data from auth.users where id = $1', [fresh])).raw_app_meta_data.role, 'organizer');

    await rejects(db.query("update public.profiles set role = 'participant' where id = $1", [fresh]), { rule: 'actionRefused' });
    await rejects(asAnon(db, (tx) => rpc(tx, 'become_organizer')), { code: '42501' });
  });

  it('never lets a client change its role, email or suspension', async () => {
    const uid = await createUser(db, { name: 'Soa Rakoto', role: 'participant' });
    await rejects(asUser(db, uid, (tx) => tx.query("update public.profiles set role = 'organizer' where id = $1", [uid])), { code: '42501' });
    await rejects(asUser(db, uid, (tx) => tx.query('update public.profiles set suspended_at = now() where id = $1', [uid])), { code: '42501' });
    await asUser(db, uid, (tx) => tx.query("update public.profiles set name = '  Soa R  ' where id = $1", [uid]));
    assert.equal((await one(db, 'select name from public.profiles where id = $1', [uid])).name, 'Soa R');
  });

  it('keeps profiles private and the API closed to anonymous callers', async () => {
    const a = await createUser(db, { name: 'Hery A', role: 'participant' });
    const b = await createUser(db, { name: 'Hery B', role: 'participant' });
    const seen = await asUser(db, a, (tx) => tx.query('select id from public.profiles'));
    assert.deepEqual(seen.rows.map((r) => r.id), [a]);
    const hidden = await asUser(db, a, (tx) => tx.query('select id from public.profiles where id = $1', [b]));
    assert.equal(hidden.rows.length, 0);
    await rejects(asAnon(db, (tx) => tx.query('select * from public.events')), { code: '42501' });
    await rejects(asAnon(db, (tx) => rpc(tx, 'reserve_seat', { p_event_id: a })), { code: '42501' });
  });

  it('keeps the server-side API out of reach of signed-in users', async () => {
    const uid = await createUser(db, { name: 'Tojo', role: 'participant' });
    for (const [name, args] of [
      ['payments_hold_seat', { p_user_id: uid, p_event_id: uid, p_tier_id: uid }],
      ['jobs_claim', { p_limit: 5 }],
      ['push_payload', { p_notification_id: uid }],
    ]) {
      await rejects(asUser(db, uid, (tx) => rpc(tx, name, args)), { code: '42501' });
    }
    await rejects(asUser(db, uid, (tx) => tx.query('select * from private.jobs')), { code: '42501' });
  });

  it('refuses every request of a suspended account at once', async () => {
    const uid = await createUser(db, { name: 'Banned', role: 'participant' });
    await db.query('update public.profiles set suspended_at = now() where id = $1', [uid]);
    await rejects(asUser(db, uid, (tx) => call(tx, 'api_pre_request')), { status: 403, rule: 'accountSuspended' });
  });

  it('registers a push token once, moving it between accounts on a shared phone', async () => {
    const a = await createUser(db, { name: 'Phone A', role: 'participant' });
    const b = await createUser(db, { name: 'Phone B', role: 'participant' });
    const args = { p_device_id: 'pixel', p_token: 'token-shared-0001', p_platform: 'android', p_locale: 'fr' };
    await asUser(db, a, (tx) => call(tx, 'register_device', args));
    await asUser(db, b, (tx) => call(tx, 'register_device', args));
    const owners = await all(db, "select user_id from public.devices where token = 'token-shared-0001'");
    assert.deepEqual(owners.map((r) => r.user_id), [b]);
  });

  it('welcomes an account once, at its first device, worded for its role, with a push queued', async () => {
    const soa = await createUser(db, { name: 'Soa Rakoto', role: 'participant' });
    const register = (deviceId, token) => asUser(db, soa, (tx) => call(tx, 'register_device', {
      p_device_id: deviceId, p_token: token, p_platform: 'android', p_locale: 'fr_FR',
    }));
    assert.equal(await one(db, "select 1 from public.notifications where user_id = $1 and type = 'welcome'", [soa]), undefined);

    await register('phone-1', 'welcome-token-0001');
    await register('phone-1', 'welcome-token-0002');
    await register('tablet-1', 'welcome-token-0003');

    const welcomes = await all(db, "select id, title, body from public.notifications where user_id = $1 and type = 'welcome'", [soa]);
    assert.equal(welcomes.length, 1);
    assert.equal(welcomes[0].title, 'Bienvenue sur EventHub, Soa');
    assert.match(welcomes[0].body, /^Inscription confirmée : vous êtes connecté\. Découvrez/);
    assert.ok((await one(db, 'select welcomed_at from public.profiles where id = $1', [soa])).welcomed_at);
    const push = await one(db, "select 1 from private.jobs where kind = 'push' and payload->>'notification_id' = $1", [welcomes[0].id]);
    assert.ok(push, 'the welcome is pushed to the device just registered');

    const org = await createUser(db, { name: 'Mirindra Rabe', role: 'organizer' });
    await asUser(db, org, (tx) => call(tx, 'register_device', {
      p_device_id: 'org-phone', p_token: 'welcome-token-0004', p_platform: 'android', p_locale: 'fr_FR',
    }));
    const orgWelcome = await one(db, "select body from public.notifications where user_id = $1 and type = 'welcome'", [org]);
    assert.match(orgWelcome.body, /en organisateur\. Publiez votre premier événement/);
    await rejects(asUser(db, soa, (tx) => tx.query('update public.profiles set welcomed_at = null where id = $1', [soa])), { code: '42501' });
  });

  it('grants the first administrator from a trusted connection, then from the app', async () => {
    const first = await createUser(db, { name: 'Admin One', role: 'participant', email: 'admin1@eventhub.test' });
    const second = await createUser(db, { name: 'Admin Two', role: 'organizer', email: 'admin2@eventhub.test' });
    await rejects(asUser(db, second, (tx) => rpc(tx, 'set_admin_role', { p_email: 'admin2@eventhub.test', p_admin: true })), { status: 403 });
    await db.query("select private.grant_admin('ADMIN1@eventhub.test')");
    await asUser(db, first, (tx) => rpc(tx, 'set_admin_role', { p_email: 'admin2@eventhub.test', p_admin: true }));
    const admins = await asUser(db, second, (tx) => tx.query('select user_id from public.administrators order by granted_at'));
    assert.equal(admins.rows.length, 2);
    await rejects(asUser(db, first, (tx) => rpc(tx, 'set_admin_role', { p_email: 'admin1@eventhub.test', p_admin: false })), { status: 409 });
    const meta = await one(db, 'select raw_app_meta_data from auth.users where id = $1', [second]);
    assert.equal(meta.raw_app_meta_data.admin, true);
  });
});

describe('events and ticket types', () => {
  let db;
  let organizer;
  let participant;
  let other;
  before(async () => {
    db = await freshDb();
    organizer = await createUser(db, { name: 'Mirindra Rabe', role: 'organizer' });
    participant = await createUser(db, { name: 'Soa Rakoto', role: 'participant' });
    other = await createUser(db, { name: 'Voahangy', role: 'participant' });
  });

  it('publishes only from a verified organizer', async () => {
    const unverified = await createUser(db, { name: 'New Org', role: 'organizer', verified: false });
    await rejects(publish(db, unverified), { status: 403, rule: 'emailNotVerified' });
    await rejects(publish(db, participant), { status: 403, rule: 'notEventOwner' });
  });

  it('returns field errors the form can show', async () => {
    const error = await rejects(publish(db, organizer, { title: 'x', capacity: 0, starts_at: 'soon' }), { status: 422, rule: 'validation' });
    const fields = JSON.parse(error.detail);
    assert.ok(fields.title && fields.capacity && fields.startsAt);
    const paid = await rejects(publish(db, organizer, { tiers: [{ name: 'VIP', capacity: 5, price: 2500 }] }), { status: 422 });
    assert.ok(JSON.parse(paid.detail).currency);
    await rejects(publish(db, organizer, { starts_at: inDays(-1) }), { status: 422 });
  });

  it('sums the types into the event, and keeps each type\'s sales across edits', async () => {
    const eventId = await publish(db, organizer, {
      currency: 'EUR',
      tiers: [{ name: 'Standard', capacity: 2 }, { name: 'VIP', capacity: 1, price: 2500 }],
    });
    let event = await one(db, 'select capacity, available_places, currency from public.events where id = $1', [eventId]);
    assert.deepEqual(event, { capacity: 3, available_places: 3, currency: 'EUR' });
    const [standard, vip] = await all(db, 'select id from public.event_tiers where event_id = $1 order by position', [eventId]);

    await asUser(db, participant, (tx) => rpc(tx, 'reserve_seat', { p_event_id: eventId, p_tier_id: standard.id }));
    await asUser(db, other, (tx) => rpc(tx, 'reserve_seat', { p_event_id: eventId, p_tier_id: standard.id }));

    const edit = (tiers, extra = {}) => asUser(db, organizer, (tx) => rpc(tx, 'save_event', {
      p_event: {
        id: eventId, title: 'Flutter Meetup', description: 'Talks.', category: 'meetup',
        starts_at: inDays(3), location: 'Antananarivo', currency: 'EUR', tiers, ...extra,
      },
    }));

    // Names swap without colliding; capacities move; sales stay.
    await edit([
      { id: standard.id, name: 'VIP', capacity: 5 },
      { id: vip.id, name: 'Standard', capacity: 2, price: 3000 },
    ]);
    event = await one(db, 'select capacity, available_places from public.events where id = $1', [eventId]);
    assert.deepEqual(event, { capacity: 7, available_places: 5 });

    await rejects(edit([{ id: standard.id, name: 'VIP', capacity: 1 }, { id: vip.id, name: 'Standard', capacity: 2, price: 3000 }]), { status: 409, rule: 'capacityBelowReservations' });
    await rejects(edit([{ id: vip.id, name: 'Standard', capacity: 2, price: 3000 }]), { status: 409, rule: 'tiersLocked' });
    await rejects(asUser(db, organizer, (tx) => rpc(tx, 'save_event', {
      p_event: { id: eventId, title: 'Flutter Meetup', description: 'Talks.', category: 'meetup', starts_at: inDays(3), location: 'Antananarivo', capacity: 50 },
    })), { status: 409, rule: 'tiersLocked' });

    // An unsold type can go.
    await edit([{ id: standard.id, name: 'VIP', capacity: 5 }]);
    assert.equal((await one(db, 'select capacity from public.events where id = $1', [eventId])).capacity, 5);
  });

  it('stores what each ticket type includes, within the app\'s limits', async () => {
    const eventId = await publish(db, organizer, {
      currency: 'EUR',
      tiers: [{ name: 'VIP', description: '  Accès backstage ', capacity: 5, price: 3000 }, { name: 'Standard', capacity: 20 }],
    });
    const rows = await all(db, 'select name, description from public.event_tiers where event_id = $1 order by position', [eventId]);
    assert.deepEqual(rows, [{ name: 'VIP', description: 'Accès backstage' }, { name: 'Standard', description: '' }]);

    const [vip] = await all(db, 'select id from public.event_tiers where event_id = $1 order by position', [eventId]);
    await asUser(db, organizer, (tx) => rpc(tx, 'save_event', {
      p_event: {
        id: eventId, title: 'Flutter Meetup', description: 'Talks.', category: 'meetup', starts_at: inDays(3),
        location: 'Tana', currency: 'EUR', tiers: [{ id: vip.id, name: 'VIP', description: 'Backstage et boisson', capacity: 5, price: 3000 }],
      },
    }));
    assert.equal((await one(db, 'select description from public.event_tiers where id = $1', [vip.id])).description, 'Backstage et boisson');

    await rejects(publish(db, organizer, { tiers: [{ name: 'x'.repeat(41), capacity: 5 }] }), { status: 422 });
    await rejects(publish(db, organizer, { tiers: [{ name: 'VIP', description: 'x'.repeat(161), capacity: 5 }] }), { status: 422 });
  });

  it('locks the single capacity once seats are sold, and never below them', async () => {
    const eventId = await publish(db, organizer, { capacity: 3 });
    await asUser(db, participant, (tx) => rpc(tx, 'reserve_seat', { p_event_id: eventId }));
    await rejects(asUser(db, organizer, (tx) => rpc(tx, 'save_event', {
      p_event: { id: eventId, title: 'Flutter Meetup', description: 'Talks.', category: 'meetup', starts_at: inDays(3), location: 'Tana', capacity: 3, tiers: [{ name: 'A', capacity: 3 }] },
    })), { rule: 'tiersLocked' });
    await rejects(asUser(db, organizer, (tx) => rpc(tx, 'save_event', {
      p_event: { id: eventId, title: 'Flutter Meetup', description: 'Talks.', category: 'meetup', starts_at: inDays(3), location: 'Tana', capacity: 0 },
    })), { status: 422 });
    await asUser(db, organizer, (tx) => rpc(tx, 'save_event', {
      p_event: { id: eventId, title: 'Flutter Meetup 2', description: 'Talks.', category: 'meetup', starts_at: inDays(4), location: 'Tana', capacity: 10 },
    }));
    const row = await one(db, 'select capacity, available_places from public.events where id = $1', [eventId]);
    assert.deepEqual(row, { capacity: 10, available_places: 9 });
    // Tickets follow the new date and title.
    const ticket = await one(db, 'select event_title from public.reservations where event_id = $1', [eventId]);
    assert.equal(ticket.event_title, 'Flutter Meetup 2');
  });

  it('lets the team edit, the owner alone delete, and only an empty event', async () => {
    const eventId = await publish(db, organizer, { capacity: 5 });
    const outsider = await createUser(db, { name: 'Outsider', role: 'organizer' });
    const payload = { id: eventId, title: 'Edited', description: 'd', category: 'meetup', starts_at: inDays(3), location: 'Tana', capacity: 5 };
    await rejects(asUser(db, outsider, (tx) => rpc(tx, 'save_event', { p_event: payload })), { status: 403, rule: 'notEventOwner' });
    await rejects(asUser(db, outsider, (tx) => call(tx, 'delete_event', { p_event_id: eventId })), { status: 403 });

    await asUser(db, participant, (tx) => rpc(tx, 'reserve_seat', { p_event_id: eventId }));
    await rejects(asUser(db, organizer, (tx) => call(tx, 'delete_event', { p_event_id: eventId })), { status: 409, rule: 'eventHasReservations' });

    const count = async () => (await one(db, 'select event_count from public.organizers where id = $1', [organizer])).event_count;
    const empty = await publish(db, organizer);
    const before = await count();
    await asUser(db, organizer, (tx) => call(tx, 'delete_event', { p_event_id: empty }));
    assert.equal(await count(), before - 1);
  });

  it('announces a new event to followers who did not opt out', async () => {
    const fan = await createUser(db, { name: 'Fan', role: 'participant' });
    const quiet = await createUser(db, { name: 'Quiet', role: 'participant' });
    for (const uid of [fan, quiet]) {
      await asUser(db, uid, (tx) => tx.query('insert into public.follows (organizer_id) values ($1)', [organizer]));
    }
    await asUser(db, quiet, (tx) => tx.query('update public.notification_preferences set followed_organizers = false where user_id = $1', [quiet]));
    assert.equal((await one(db, 'select follower_count from public.organizers where id = $1', [organizer])).follower_count, 2);

    const eventId = await publish(db, organizer, { title: 'Concert Jazz' });
    const received = await all(db, "select user_id, title, body from public.notifications where event_id = $1 and type = 'newEvent'", [eventId]);
    assert.deepEqual(received.map((n) => n.user_id), [fan]);
    assert.match(received[0].body, /« Concert Jazz » · \w+ \d+ \w+ à \d\d:\d\d · Antananarivo\./);

    // Following oneself is refused by the table itself.
    await rejects(asUser(db, organizer, (tx) => tx.query('insert into public.follows (organizer_id) values ($1)', [organizer])), { code: '23514' });
  });
});
