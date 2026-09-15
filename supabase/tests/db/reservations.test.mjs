import assert from 'node:assert/strict';
import { before, describe, it } from 'node:test';

import { all, asUser, call, createUser, freshDb, inDays, one, publish, rejects, rpc } from './helpers.mjs';

describe('reservations, waiting list, door', () => {
  let db;
  let organizer;
  let staff;
  let outsider;
  let soa;
  let hery;
  before(async () => {
    db = await freshDb();
    organizer = await createUser(db, { name: 'Mirindra Rabe', role: 'organizer' });
    staff = await createUser(db, { name: 'Co Org', role: 'organizer', email: 'staff@eventhub.test' });
    outsider = await createUser(db, { name: 'Other Org', role: 'organizer' });
    soa = await createUser(db, { name: 'Soa Rakoto', role: 'participant' });
    hery = await createUser(db, { name: 'Hery Randria', role: 'participant' });
  });

  const reserve = (uid, eventId, tierId = null) =>
    asUser(db, uid, (tx) => rpc(tx, 'reserve_seat', { p_event_id: eventId, p_tier_id: tierId }));
  const places = async (eventId) =>
    (await one(db, 'select available_places from public.events where id = $1', [eventId])).available_places;

  it('books one seat per person and never overbooks', async () => {
    const eventId = await publish(db, organizer, { capacity: 1 });
    await asUser(db, organizer, (tx) => rpc(tx, 'invite_co_organizer', { p_event_id: eventId, p_email: 'staff@eventhub.test' }));
    await asUser(db, staff, (tx) => rpc(tx, 'respond_to_staff_invite', { p_event_id: eventId, p_accept: true }));

    const ticket = await reserve(soa, eventId);
    assert.equal(ticket.status, 'confirmed');
    assert.equal(ticket.user_name, 'Soa Rakoto');
    assert.equal(await places(eventId), 0);

    await rejects(reserve(soa, eventId), { status: 409, rule: 'alreadyReserved' });
    await rejects(reserve(hery, eventId), { status: 409, rule: 'eventFull' });
    await rejects(reserve(organizer, eventId), { status: 409, rule: 'actionRefused' });
    await rejects(reserve(staff, eventId), { status: 409, rule: 'actionRefused' });

    const alerts = await all(db, "select user_id from public.notifications where type = 'booking' and event_id = $1 order by user_id", [eventId]);
    assert.deepEqual(alerts.map((a) => a.user_id).sort(), [organizer, staff].sort());
  });

  it('lets an organizer book, queue and review at other people\'s events, like any account', async () => {
    const eventId = await publish(db, organizer, { capacity: 1 });
    const ticket = await reserve(outsider, eventId);
    assert.equal(ticket.status, 'confirmed');
    assert.equal(ticket.user_name, 'Other Org');
    await asUser(db, soa, (tx) => call(tx, 'join_waitlist', { p_event_id: eventId }));
    await rejects(asUser(db, organizer, (tx) => call(tx, 'join_waitlist', { p_event_id: eventId })), { status: 409, rule: 'actionRefused' });

    await db.query("update public.events set starts_at = now() - interval '1 hour' where id = $1", [eventId]);
    await asUser(db, outsider, (tx) => tx.query('insert into public.reviews (event_id, rating, comment) values ($1, 5, $2)', [eventId, 'Très bien organisé']));
    assert.equal((await one(db, 'select count(*)::int as n from public.reviews where event_id = $1', [eventId])).n, 1);
  });

  it('shows a guest list to the team only', async () => {
    const eventId = await publish(db, organizer, { capacity: 5 });
    await asUser(db, organizer, (tx) => rpc(tx, 'invite_co_organizer', { p_event_id: eventId, p_email: 'staff@eventhub.test' }));
    await reserve(soa, eventId);
    await reserve(hery, eventId);
    const count = (uid) => asUser(db, uid, async (tx) => (await tx.query('select id from public.reservations where event_id = $1', [eventId])).rows.length);

    assert.equal(await count(organizer), 2);
    assert.equal(await count(staff), 0, 'a pending invitation is not membership');
    await asUser(db, staff, (tx) => rpc(tx, 'respond_to_staff_invite', { p_event_id: eventId, p_accept: true }));
    assert.equal(await count(staff), 2);
    assert.equal(await count(outsider), 0);
    assert.equal(await count(soa), 1);
    await rejects(asUser(db, soa, (tx) => tx.query("update public.reservations set status = 'cancelled' where event_id = $1", [eventId])), { code: '42501' });
  });

  it('gives the seat back on cancellation and tells the waiting list', async () => {
    const eventId = await publish(db, organizer, { capacity: 1 });
    const ticket = await reserve(soa, eventId);
    await asUser(db, hery, (tx) => call(tx, 'join_waitlist', { p_event_id: eventId }));
    await rejects(asUser(db, soa, (tx) => call(tx, 'join_waitlist', { p_event_id: eventId })), { rule: 'alreadyReserved' });
    await rejects(asUser(db, hery, (tx) => rpc(tx, 'cancel_reservation', { p_reservation_id: ticket.id })), { status: 403, rule: 'notReservationOwner' });

    const cancelled = await asUser(db, soa, (tx) => rpc(tx, 'cancel_reservation', { p_reservation_id: ticket.id }));
    assert.equal(cancelled.status, 'cancelled');
    assert.equal(await places(eventId), 1);
    await rejects(asUser(db, soa, (tx) => rpc(tx, 'cancel_reservation', { p_reservation_id: ticket.id })), { rule: 'reservationNotActive' });

    const waitlist = await one(db, "select body from public.notifications where user_id = $1 and type = 'waitlist'", [hery]);
    assert.match(waitlist.body, /1 place disponible\. Premier arrivé/);
    assert.ok((await one(db, 'select notified_at from public.waitlist_entries where user_id = $1', [hery])).notified_at);
    await rejects(asUser(db, soa, (tx) => call(tx, 'join_waitlist', { p_event_id: eventId })), { rule: 'waitlistNotAvailable' });

    // Booking ends the wait; a re-booking reuses the ticket.
    await reserve(hery, eventId);
    assert.equal(await one(db, 'select 1 from public.waitlist_entries where user_id = $1', [hery]), undefined);
    const heryTicket = await one(db, 'select id from public.reservations where event_id = $1 and user_id = $2', [eventId, hery]);
    await asUser(db, hery, (tx) => rpc(tx, 'cancel_reservation', { p_reservation_id: heryTicket.id }));
    const rebooked = await reserve(soa, eventId);
    assert.equal(rebooked.id, ticket.id);
    assert.equal(rebooked.cancelled_at, null);
  });

  it('books a free ticket type, and sends paid types to checkout', async () => {
    const eventId = await publish(db, organizer, {
      currency: 'MGA',
      tiers: [{ name: 'Invités', capacity: 1 }, { name: 'Fosse', capacity: 10, price: 20000 }],
    });
    const [free, paid] = await all(db, 'select id from public.event_tiers where event_id = $1 order by position', [eventId]);
    await rejects(reserve(soa, eventId), { rule: 'tierRequired' });
    await rejects(reserve(soa, eventId, paid.id), { status: 409, rule: 'paymentRequired' });
    const ticket = await reserve(soa, eventId, free.id);
    assert.equal(ticket.tier_name, 'Invités');
    assert.equal((await one(db, 'select available from public.event_tiers where id = $1', [free.id])).available, 0);
    assert.equal(await places(eventId), 10);
    await rejects(reserve(hery, eventId, free.id), { rule: 'tierSoldOut' });
  });

  it('closes booking once the event has started', async () => {
    const eventId = await publish(db, organizer, { capacity: 5 });
    await db.query("update public.events set starts_at = now() - interval '1 minute' where id = $1", [eventId]);
    await rejects(reserve(soa, eventId), { rule: 'eventAlreadyStarted' });
  });

  it('decides the door verdict atomically, for the team only', async () => {
    const eventId = await publish(db, organizer, { capacity: 5 });
    const elsewhere = await publish(db, organizer, { capacity: 5 });
    const ticket = await reserve(soa, eventId);
    const cancelled = await reserve(hery, eventId);
    await asUser(db, hery, (tx) => rpc(tx, 'cancel_reservation', { p_reservation_id: cancelled.id }));
    const scan = (uid, event, reservation) => asUser(db, uid, (tx) => rpc(tx, 'check_in_ticket', { p_event_id: event, p_reservation_id: reservation }));

    await rejects(scan(outsider, eventId, ticket.id), { status: 403 });
    assert.equal((await scan(organizer, eventId, ticket.id)).status, 'admitted');
    const again = await scan(organizer, eventId, ticket.id);
    assert.equal(again.status, 'alreadyCheckedIn');
    assert.ok(again.scanned_at);
    assert.equal((await scan(organizer, elsewhere, ticket.id)).status, 'wrongEvent');
    assert.equal((await scan(organizer, eventId, cancelled.id)).status, 'cancelled');
    assert.equal((await scan(organizer, eventId, organizer)).status, 'notFound');
  });

  it('shows short names only, and the exact head count', async () => {
    const eventId = await publish(db, organizer, { capacity: 5 });
    await reserve(soa, eventId);
    await reserve(hery, eventId);
    const attendance = await asUser(db, outsider, (tx) => rpc(tx, 'event_attendance', { p_event_id: eventId }));
    assert.equal(attendance.count, 2);
    assert.deepEqual(attendance.recent.map((a) => a.name), ['Hery R.', 'Soa R.']);
    assert.equal(attendance.recent[0].key.length, 16);
  });

  it('reminds each ticket holder once, the day before', async () => {
    const eventId = await publish(db, organizer, { capacity: 5, starts_at: new Date(Date.now() + 23 * 3600e3).toISOString() });
    await reserve(soa, eventId);
    assert.equal((await one(db, 'select private.send_event_reminders(now()) as n')).n, 1);
    assert.equal((await one(db, 'select private.send_event_reminders(now()) as n')).n, 0);
    const reminder = await one(db, "select title from public.notifications where user_id = $1 and type = 'reminder'", [soa]);
    assert.equal(reminder.title, 'Demain : Flutter Meetup');
  });

  it('queues a push only for recipients with a device', async () => {
    const eventId = await publish(db, organizer, { capacity: 5, starts_at: inDays(5) });
    const before = (await one(db, "select count(*)::int as n from private.jobs where kind = 'push'")).n;
    await reserve(soa, eventId);
    assert.equal((await one(db, "select count(*)::int as n from private.jobs where kind = 'push'")).n, before);
    await asUser(db, organizer, (tx) => call(tx, 'register_device', { p_device_id: 'd1', p_token: 'organizer-token-1', p_platform: 'android', p_locale: 'fr' }));
    await reserve(hery, eventId);
    const job = await one(db, "select payload from private.jobs where kind = 'push' order by id desc limit 1");
    const notification = await one(db, 'select user_id, type from public.notifications where id = $1', [job.payload.notification_id]);
    assert.deepEqual(notification, { user_id: organizer, type: 'booking' });
  });
});
