import assert from 'node:assert/strict';
import { before, describe, it } from 'node:test';

import { all, asService, asUser, createUser, freshDb, one, publish, rejects, rpc } from './helpers.mjs';

describe('payments', () => {
  let db;
  let organizer;
  let soa;
  let hery;
  before(async () => {
    db = await freshDb();
    organizer = await createUser(db, { name: 'Mirindra Rabe', role: 'organizer' });
    soa = await createUser(db, { name: 'Soa Rakoto', role: 'participant' });
    hery = await createUser(db, { name: 'Hery Randria', role: 'participant' });
  });

  async function paidEvent(vipSeats = 1) {
    const eventId = await publish(db, organizer, {
      currency: 'EUR',
      tiers: [{ name: 'Standard', capacity: 10 }, { name: 'VIP', capacity: vipSeats, price: 2500 }],
    });
    const [standard, vip] = await all(db, 'select id from public.event_tiers where event_id = $1 order by position', [eventId]);
    return { eventId, standard: standard.id, vip: vip.id };
  }
  const svc = (name, args) => asService(db, (tx) => rpc(tx, name, args));
  const hold = (uid, eventId, tierId) => svc('payments_hold_seat', { p_user_id: uid, p_event_id: eventId, p_tier_id: tierId, p_hold_minutes: 30 });
  const vipLeft = async (tierId) => (await one(db, 'select available from public.event_tiers where id = $1', [tierId])).available;
  const reservation = (id) => one(db, 'select * from public.reservations where id = $1', [id]);

  it('holds a paid seat, resumes the same session, and blocks a free booking meanwhile', async () => {
    const { eventId, standard, vip } = await paidEvent(2);
    const first = await hold(soa, eventId, vip);
    assert.equal(first.price, 2500);
    assert.equal(first.currency, 'EUR');
    assert.equal(first.reused_url, null);
    assert.equal(await vipLeft(vip), 1);
    const held = await reservation(first.reservation_id);
    assert.equal(held.status, 'pending');
    assert.ok(new Date(held.hold_expires_at) > new Date(first.expires_at), 'released after Stripe expires the session');

    await svc('payments_attach_session', { p_reservation_id: first.reservation_id, p_session_id: 'cs_1', p_url: 'https://checkout.stripe.com/c/cs_1' });
    const resumed = await hold(soa, eventId, vip);
    assert.equal(resumed.reused_url, 'https://checkout.stripe.com/c/cs_1');
    assert.equal(await vipLeft(vip), 1, 'resuming takes no second seat');

    await rejects(asUser(db, soa, (tx) => rpc(tx, 'reserve_seat', { p_event_id: eventId, p_tier_id: standard })), { rule: 'paymentPending' });
    await rejects(hold(soa, eventId, standard), { status: 409 });
    await rejects(hold(organizer, eventId, vip), { status: 403 });
  });

  it('confirms through the webhook once, and refuses a direct cancellation', async () => {
    const { eventId, vip } = await paidEvent();
    const { reservation_id: id } = await hold(soa, eventId, vip);
    assert.equal(await svc('payments_fulfill', { p_reservation_id: id, p_payment_intent_id: 'pi_1', p_amount: 2500, p_currency: 'eur', p_session_id: 'cs_2' }), 'confirmed');
    assert.equal(await svc('payments_fulfill', { p_reservation_id: id, p_payment_intent_id: 'pi_1', p_amount: 2500, p_currency: 'eur', p_session_id: 'cs_2' }), 'already');
    const ticket = await reservation(id);
    assert.equal(ticket.status, 'confirmed');
    assert.equal(ticket.price_paid, 2500);
    assert.equal(ticket.payment_status, 'paid');
    assert.ok(await one(db, "select 1 from public.notifications where user_id = $1 and type = 'paymentConfirmed'", [soa]));
    await rejects(asUser(db, soa, (tx) => rpc(tx, 'cancel_reservation', { p_reservation_id: id })), { rule: 'refundRequired' });
  });

  it('re-seats a late payment when a seat is left, refunds it otherwise', async () => {
    const { eventId, standard, vip } = await paidEvent(1);
    const late = await hold(soa, eventId, vip);
    assert.equal(await svc('payments_release_hold', { p_reservation_id: late.reservation_id, p_outcome: 'expired' }), true);
    assert.equal(await svc('payments_release_hold', { p_reservation_id: late.reservation_id, p_outcome: 'expired' }), false);
    assert.equal(await vipLeft(vip), 1);
    assert.equal(await svc('payments_fulfill', { p_reservation_id: late.reservation_id, p_payment_intent_id: 'pi_late', p_amount: 2500, p_currency: 'EUR', p_session_id: 'cs_late' }), 'confirmed');
    assert.equal(await vipLeft(vip), 0);

    const second = await paidEvent(1);
    const lost = await hold(soa, second.eventId, second.vip);
    await svc('payments_release_hold', { p_reservation_id: lost.reservation_id, p_outcome: 'expired' });
    const winner = await hold(hery, second.eventId, second.vip);
    await svc('payments_fulfill', { p_reservation_id: winner.reservation_id, p_payment_intent_id: 'pi_w', p_amount: 2500, p_currency: 'EUR', p_session_id: 'cs_w' });
    assert.equal(await svc('payments_fulfill', { p_reservation_id: lost.reservation_id, p_payment_intent_id: 'pi_lost', p_amount: 2500, p_currency: 'EUR', p_session_id: 'cs_lost' }), 'refund');
    await asService(db, (tx) => tx.query("select public.payments_mark_refunded($1, 'pi_lost', 're_1')", [lost.reservation_id]));
    const refunded = await reservation(lost.reservation_id);
    assert.equal(refunded.status, 'cancelled');
    assert.equal(refunded.payment_status, 'refunded');
    assert.ok(await one(db, "select 1 from public.notifications where reservation_id = $1 and type = 'paymentRefunded'", [lost.reservation_id]));
    assert.equal(await vipLeft(second.vip), 0);
    void standard;
  });

  it('sweeps expired holds', async () => {
    const { eventId, vip } = await paidEvent(1);
    const { reservation_id: id } = await hold(hery, eventId, vip);
    await db.query("update public.reservations set hold_expires_at = now() - interval '1 minute' where id = $1", [id]);
    assert.equal((await one(db, 'select private.release_expired_holds(now()) as n')).n, 1);
    assert.equal((await reservation(id)).payment_status, 'expired');
    assert.equal(await vipLeft(vip), 1);
  });

  it('refunds a paid ticket before the event, then puts the seat back on sale', async () => {
    const { eventId, vip } = await paidEvent(1);
    const { reservation_id: id } = await hold(soa, eventId, vip);
    await svc('payments_fulfill', { p_reservation_id: id, p_payment_intent_id: 'pi_r', p_amount: 2500, p_currency: 'EUR', p_session_id: 'cs_r' });
    await rejects(svc('payments_begin_refund', { p_user_id: hery, p_event_id: eventId }), { status: 404 });
    const begun = await svc('payments_begin_refund', { p_user_id: soa, p_event_id: eventId });
    assert.equal(begun.payment_intent_id, 'pi_r');
    assert.equal(await svc('payments_complete_refund', { p_reservation_id: id, p_refund_id: 're_r' }), true);
    assert.equal(await svc('payments_complete_refund', { p_reservation_id: id, p_refund_id: 're_r' }), false);
    assert.equal(await vipLeft(vip), 1);
    await rejects(svc('payments_begin_refund', { p_user_id: soa, p_event_id: eventId }), { rule: 'reservationNotActive' });

    // The currency is locked once money moved.
    const tiers = await all(db, 'select id, name, price, capacity from public.event_tiers where event_id = $1 order by position', [eventId]);
    await rejects(asUser(db, organizer, (tx) => rpc(tx, 'save_event', {
      p_event: {
        id: eventId, title: 'Flutter Meetup', description: 'Talks.', category: 'meetup',
        starts_at: new Date(Date.now() + 3 * 86400e3).toISOString(), location: 'Tana', currency: 'USD', tiers,
      },
    })), { status: 409, rule: 'tiersLocked' });
  });

  it('lets the buyer give up a held seat', async () => {
    const { eventId, vip } = await paidEvent(1);
    const { reservation_id: id } = await hold(hery, eventId, vip);
    await svc('payments_attach_session', { p_reservation_id: id, p_session_id: 'cs_giveup', p_url: 'https://checkout.stripe.com/c/x' });
    const released = await svc('payments_release_own_hold', { p_user_id: hery, p_event_id: eventId });
    assert.deepEqual(released, { released: true, session_id: 'cs_giveup' });
    assert.equal((await reservation(id)).payment_status, 'cancelled');
  });
});
