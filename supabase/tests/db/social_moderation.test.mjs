import assert from 'node:assert/strict';
import { before, describe, it } from 'node:test';

import { all, asService, asUser, call, createUser, freshDb, one, publish, rejects, rpc } from './helpers.mjs';

describe('reviews, reports, moderation', () => {
  let db;
  let organizer;
  let admin;
  let soa;
  let hery;
  let tojo;
  let naina;
  let eventId;
  let reviewId;
  before(async () => {
    db = await freshDb();
    organizer = await createUser(db, { name: 'Mirindra Rabe', role: 'organizer' });
    admin = await createUser(db, { name: 'Admin', role: 'participant', email: 'admin@eventhub.test' });
    await db.query("select private.grant_admin('admin@eventhub.test')");
    soa = await createUser(db, { name: 'Soa Rakoto', role: 'participant' });
    hery = await createUser(db, { name: 'Hery Randria', role: 'participant' });
    tojo = await createUser(db, { name: 'Tojo', role: 'participant' });
    naina = await createUser(db, { name: 'Naina', role: 'participant' });
    eventId = await publish(db, organizer, { capacity: 10 });
    for (const uid of [soa, hery]) {
      await asUser(db, uid, (tx) => rpc(tx, 'reserve_seat', { p_event_id: eventId }));
    }
  });

  const review = (uid, rating, comment = '') =>
    asUser(db, uid, (tx) => tx.query('insert into public.reviews (event_id, rating, comment) values ($1, $2, $3) returning id', [eventId, rating, comment]));
  const report = (uid, targetType, targetId, reason = 'spam', details = '') =>
    asUser(db, uid, (tx) => tx.query('insert into public.reports (target_type, target_id, reason, details) values ($1, $2, $3, $4)', [targetType, targetId, reason, details]));

  it('lets attendees review only once the event has started', async () => {
    await rejects(review(soa, 5), { code: '42501' });
    await db.query("update public.events set starts_at = now() - interval '1 hour' where id = $1", [eventId]);
    await rejects(review(tojo, 5), { code: '42501' });
    reviewId = (await review(soa, 5, 'Super')).rows[0].id;
    await review(hery, 3);
    const org = await one(db, 'select rating_sum, rating_count from public.organizers where id = $1', [organizer]);
    assert.deepEqual(org, { rating_sum: 8, rating_count: 2 });
    const row = await one(db, 'select author_name, author_id from public.reviews where id = $1', [reviewId]);
    assert.deepEqual(row, { author_name: 'Soa Rakoto', author_id: soa });
    await rejects(asUser(db, soa, (tx) => tx.query('update public.reviews set hidden = true where id = $1', [reviewId])), { code: '42501' });
  });

  it('counts one report per person and hides a review at three', async () => {
    await rejects(report(soa, 'review', reviewId), { rule: 'cannotReportSelf' });
    await rejects(report(hery, 'user', hery), { rule: 'cannotReportSelf' });
    await rejects(report(hery, 'review', reviewId, 'other'), { status: 422 });
    await report(hery, 'review', reviewId);
    await rejects(report(hery, 'review', reviewId), { code: '23505' });
    await report(tojo, 'review', reviewId, 'inappropriate');
    assert.equal((await one(db, 'select hidden from public.reviews where id = $1', [reviewId])).hidden, false);
    await report(naina, 'review', reviewId, 'harassment');

    assert.equal((await one(db, 'select hidden from public.reviews where id = $1', [reviewId])).hidden, true);
    const entry = await one(db, 'select id, report_count, auto_hidden, last_reason from public.moderation_queue where target_id = $1', [reviewId]);
    assert.deepEqual(entry, { id: `review_${reviewId}`, report_count: 3, auto_hidden: true, last_reason: 'harassment' });
    assert.ok(await one(db, "select 1 from public.notifications where user_id = $1 and type = 'reviewHidden'", [soa]));
    assert.equal((await one(db, 'select rating_count from public.organizers where id = $1', [organizer])).rating_count, 1);

    const visibleTo = (uid) => asUser(db, uid, async (tx) => (await tx.query('select id from public.reviews where id = $1', [reviewId])).rows.length);
    assert.equal(await visibleTo(hery), 0);
    assert.equal(await visibleTo(soa), 1);
    assert.equal(await visibleTo(admin), 1);
    assert.equal(await asUser(db, hery, async (tx) => (await tx.query('select * from public.reports')).rows.length), 0);
  });

  it('keeps a moderator\'s decision over the automatic threshold', async () => {
    await rejects(asUser(db, hery, (tx) => rpc(tx, 'moderate_content', { p_target_type: 'review', p_target_id: reviewId, p_action: 'restore', p_note: '' })), { status: 403 });
    await rejects(asUser(db, admin, (tx) => rpc(tx, 'moderate_content', { p_target_type: 'review', p_target_id: reviewId, p_action: 'suspend', p_note: 'x' })), { status: 422 });
    await asUser(db, admin, (tx) => rpc(tx, 'moderate_content', { p_target_type: 'review', p_target_id: reviewId, p_action: 'restore', p_note: '' }));
    const extra = await createUser(db, { name: 'Late Reporter', role: 'participant' });
    await report(extra, 'review', reviewId);
    assert.equal((await one(db, 'select hidden from public.reviews where id = $1', [reviewId])).hidden, false);
    const decisions = await asUser(db, admin, (tx) => tx.query('select action from public.moderation_decisions where target_id = $1', [reviewId]));
    assert.deepEqual(decisions.rows.map((d) => d.action), ['restore']);
    assert.equal((await one(db, 'select status from public.moderation_queue where target_id = $1', [reviewId])).status, 'open');
  });

  it('suspends an account everywhere at once, and reinstates it', async () => {
    const moderate = (action, note = 'Spam répété') => asUser(db, admin, (tx) => rpc(tx, 'moderate_content', { p_target_type: 'user', p_target_id: tojo, p_action: action, p_note: note }));
    await db.query('insert into auth.sessions (user_id) values ($1)', [tojo]);
    await rejects(moderate('suspend', ''), { status: 422 });
    await rejects(asUser(db, admin, (tx) => rpc(tx, 'moderate_content', { p_target_type: 'user', p_target_id: admin, p_action: 'suspend', p_note: 'x' })), { status: 409 });
    await moderate('suspend');
    assert.ok((await one(db, 'select banned_until from auth.users where id = $1', [tojo])).banned_until);
    assert.equal(await one(db, 'select 1 from auth.sessions where user_id = $1', [tojo]), undefined);
    await rejects(asUser(db, tojo, (tx) => call(tx, 'api_pre_request')), { rule: 'accountSuspended' });
    await moderate('reinstate', '');
    await asUser(db, tojo, (tx) => call(tx, 'api_pre_request'));
  });

  it('removes an event: seats cancelled, refunds queued, people told once', async () => {
    const paid = await publish(db, organizer, { currency: 'EUR', tiers: [{ name: 'VIP', capacity: 5, price: 1000 }] });
    const { id: vip } = await one(db, 'select id from public.event_tiers where event_id = $1', [paid]);
    const held = await asService(db, (tx) => rpc(tx, 'payments_hold_seat', { p_user_id: naina, p_event_id: paid, p_tier_id: vip, p_hold_minutes: 30 }));
    await asService(db, (tx) => rpc(tx, 'payments_fulfill', { p_reservation_id: held.reservation_id, p_payment_intent_id: 'pi_mod', p_amount: 1000, p_currency: 'EUR', p_session_id: 'cs_mod' }));
    await report(hery, 'event', paid, 'fraud');

    const outcome = await asUser(db, admin, (tx) => rpc(tx, 'moderate_content', { p_target_type: 'event', p_target_id: paid, p_action: 'removeEvent', p_note: 'Arnaque' }));
    assert.equal(outcome.cancelled_reservations, 1);
    assert.equal(await one(db, 'select 1 from public.events where id = $1', [paid]), undefined);
    const ticket = await one(db, 'select event_id, status, cancelled_by from public.reservations where id = $1', [held.reservation_id]);
    assert.deepEqual(ticket, { event_id: null, status: 'cancelled', cancelled_by: 'moderation' });
    const refund = await one(db, "select payload from private.jobs where kind = 'refund'");
    assert.equal(refund.payload.payment_intent_id, 'pi_mod');
    const organizerNotices = await all(db, "select body from public.notifications where user_id = $1 and type in ('eventRemoved', 'cancellation')", [organizer]);
    assert.equal(organizerNotices.length, 1);
    assert.match(organizerNotices[0].body, /Arnaque/);
    assert.equal((await one(db, 'select status from public.moderation_queue where target_id = $1', [paid])).status, 'resolved');
  });
});

describe('team, account deletion, job queue', () => {
  let db;
  let owner;
  let member;
  let participant;
  before(async () => {
    db = await freshDb();
    owner = await createUser(db, { name: 'Owner', role: 'organizer' });
    member = await createUser(db, { name: 'Member Org', role: 'organizer', email: 'member@eventhub.test' });
    participant = await createUser(db, { name: 'Soa Rakoto', role: 'participant', email: 'soa@eventhub.test' });
  });

  it('invites organizers only, lets them answer once, and lets them leave', async () => {
    const eventId = await publish(db, owner, { capacity: 5 });
    const invite = (email, uid = owner) => asUser(db, uid, (tx) => rpc(tx, 'invite_co_organizer', { p_event_id: eventId, p_email: email }));
    await rejects(invite('soa@eventhub.test'), { rule: 'actionRefused' });
    await rejects(invite('nobody@eventhub.test'), { status: 404 });
    await rejects(invite('not-an-email'), { status: 422 });
    await rejects(invite('member@eventhub.test', member), { status: 403 });
    assert.equal((await invite('MEMBER@eventhub.test')).user_id, member);
    assert.ok(await one(db, "select 1 from public.notifications where user_id = $1 and type = 'staffInvite'", [member]));

    await asUser(db, member, (tx) => rpc(tx, 'respond_to_staff_invite', { p_event_id: eventId, p_accept: true }));
    await rejects(asUser(db, member, (tx) => rpc(tx, 'respond_to_staff_invite', { p_event_id: eventId, p_accept: true })), { status: 404 });
    assert.ok(await one(db, "select 1 from public.notifications where user_id = $1 and type = 'staffJoined'", [owner]));
    await rejects(asUser(db, member, (tx) => call(tx, 'remove_co_organizer', { p_event_id: eventId, p_user_id: owner })), { status: 403 });

    await asUser(db, owner, (tx) => call(tx, 'remove_co_organizer', { p_event_id: eventId, p_user_id: member }));
    assert.ok(await one(db, "select 1 from public.notifications where user_id = $1 and type = 'staffRemoved'", [member]));
    assert.equal(await one(db, 'select 1 from public.event_staff where event_id = $1', [eventId]), undefined);
  });

  it('refuses to delete an organizer with upcoming participants, deletes a participant cleanly', async () => {
    const eventId = await publish(db, owner, { capacity: 3 });
    const ticket = await asUser(db, participant, (tx) => rpc(tx, 'reserve_seat', { p_event_id: eventId }));
    await asUser(db, participant, (tx) => tx.query('insert into public.follows (organizer_id) values ($1)', [owner]));
    await rejects(asUser(db, owner, (tx) => rpc(tx, 'delete_my_account')), { rule: 'actionRefused' });

    assert.deepEqual(await asUser(db, participant, (tx) => rpc(tx, 'delete_my_account')), { deleted: true });
    assert.equal(await one(db, 'select 1 from auth.users where id = $1', [participant]), undefined);
    const history = await one(db, 'select user_id, user_name, status, cancelled_by from public.reservations where id = $1', [ticket.id]);
    assert.deepEqual(history, { user_id: null, user_name: 'Compte supprimé', status: 'cancelled', cancelled_by: 'account_deleted' });
    assert.equal((await one(db, 'select available_places from public.events where id = $1', [eventId])).available_places, 3);
    assert.equal((await one(db, 'select follower_count from public.organizers where id = $1', [owner])).follower_count, 0);
    const alert = await one(db, "select body from public.notifications where user_id = $1 and type = 'cancellation'", [owner]);
    assert.match(alert.body, /^Compte supprimé a libéré sa place/);
    assert.ok(await one(db, "select 1 from private.jobs where kind = 'storage.delete' and payload->>'bucket' = 'avatars'"));
  });

  it('claims jobs without overlap, backs off, and flags a refund that never succeeds', async () => {
    await db.query("insert into private.jobs (kind, payload) values ('refund', $1)", [JSON.stringify({ reservation_id: '00000000-0000-0000-0000-000000000000', payment_intent_id: 'pi_x' })]);
    const claimed = await asService(db, (tx) => rpc(tx, 'jobs_claim', { p_limit: 50 }));
    assert.ok(claimed.length >= 1);
    assert.deepEqual(await asService(db, (tx) => rpc(tx, 'jobs_claim', { p_limit: 50 })), []);

    const refund = claimed.find((j) => j.kind === 'refund');
    assert.equal(await asService(db, (tx) => rpc(tx, 'jobs_fail', { p_job_id: refund.id, p_error: 'card_declined' })), 'queued');
    const retry = await one(db, 'select run_after > now() as later from private.jobs where id = $1', [refund.id]);
    assert.equal(retry.later, true);
    await db.query('update private.jobs set attempts = 8 where id = $1', [refund.id]);
    assert.equal(await asService(db, (tx) => rpc(tx, 'jobs_fail', { p_job_id: refund.id, p_error: 'still failing' })), 'failed');

    for (const job of claimed.filter((j) => j.kind !== 'refund')) {
      await asService(db, (tx) => rpc(tx, 'jobs_complete', { p_job_id: job.id }));
    }
    assert.equal((await one(db, "select count(*)::int as n from private.jobs where status = 'running'")).n, 0);
  });

  it('schedules the recurring work', async () => {
    const jobs = await all(db, 'select jobname from cron.job order by jobname');
    assert.deepEqual(jobs.map((j) => j.jobname), ['eventhub-event-reminders', 'eventhub-purge', 'eventhub-release-holds', 'eventhub-worker']);
  });
});
