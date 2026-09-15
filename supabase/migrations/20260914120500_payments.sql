-- =============================================================================
--  EventHub · 6/8 · Payments (F-11)
--  The database half of Stripe Checkout. The Edge Functions talk to Stripe;
--  every seat and money state change happens here, in a transaction. These
--  functions are executable by `service_role` only — no client can hold a
--  seat, confirm a payment or record a refund.
--
--    payments-checkout  → payments_hold_seat, payments_attach_session,
--                         payments_release_hold ('failed')
--    payments-cancel    → payments_release_hold ('cancelled')
--    stripe-webhook     → payments_fulfill, payments_mark_refunded,
--                         payments_release_hold ('expired')
--    payments-refund    → payments_begin_refund, payments_complete_refund
--    worker (refunds)   → payments_refund_settled
--    pg_cron            → private.release_expired_holds
-- =============================================================================

-- A seat of a paid type held for the buyer while they are on the Stripe page.
-- Returns what the checkout session needs; `reused_url` is set when an open
-- session for the same type can simply be resumed.
create function public.payments_hold_seat(
  p_user_id uuid,
  p_event_id uuid,
  p_tier_id uuid,
  p_hold_minutes integer default 30
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  -- Released a little after Stripe expires the session, never before.
  v_grace constant interval := interval '5 minutes';
  v_expires_at timestamptz := now() + make_interval(mins => p_hold_minutes);
  v_profile public.profiles%rowtype;
  v_event public.events%rowtype;
  v_tier public.event_tiers%rowtype;
  v_res public.reservations%rowtype;
  v_previous_tier uuid;
  v_has_previous boolean := false;
begin
  select * into v_profile from public.profiles p where p.id = p_user_id;
  if not found or v_profile.role <> 'participant' then
    perform private.fail(403, 'actionRefused', 'Seul un participant peut acheter un billet.');
  end if;
  if v_profile.suspended_at is not null then
    perform private.fail(403, 'accountSuspended', 'Ce compte est suspendu par la modération.');
  end if;

  select * into v_event from public.events e where e.id = p_event_id for update;
  if not found then
    perform private.fail(404, 'notFound', 'Cet événement n''existe plus.');
  end if;
  if v_event.starts_at <= now() then
    perform private.fail(409, 'eventAlreadyStarted', 'Cet événement a déjà commencé.');
  end if;

  select * into v_res from public.reservations r
  where r.event_id = p_event_id and r.user_id = p_user_id
  for update;
  if found and v_res.status = 'confirmed' then
    perform private.fail(409, 'alreadyReserved', 'Vous avez déjà une place pour cet événement.');
  end if;

  select * into v_tier from public.event_tiers t
  where t.id = p_tier_id and t.event_id = p_event_id
  for update;
  if not found then
    perform private.fail(404, 'tierRequired', 'Ce type de billet n''existe plus.');
  end if;
  if v_tier.price <= 0 then
    perform private.fail(409, 'actionRefused', 'Ce billet est gratuit : réservez-le directement.');
  end if;
  if v_event.currency is null then
    perform private.fail(409, 'actionRefused', 'Ce billet n''a pas de devise : contactez l''organisateur.');
  end if;

  if v_res.status = 'pending' then
    if v_res.tier_id = p_tier_id
       and v_res.checkout_url is not null
       and v_res.hold_expires_at - v_grace > now() + interval '1 minute' then
      return jsonb_build_object(
        'reservation_id', v_res.id,
        'reused_url', v_res.checkout_url,
        'price', v_tier.price,
        'currency', v_event.currency,
        'tier_name', v_tier.name,
        'event_title', v_event.title,
        'email', v_profile.email,
        'expires_at', v_res.hold_expires_at - v_grace
      );
    end if;
    v_has_previous := true;
    v_previous_tier := v_res.tier_id;
  end if;

  -- A still-held seat of the same type is reused; one of another type is
  -- given back in the same transaction.
  if not (v_has_previous and v_previous_tier = p_tier_id) then
    if v_tier.available <= 0 then
      perform private.fail(409, 'tierSoldOut', format('Le billet « %s » est complet.', v_tier.name));
    end if;
    update public.event_tiers set available = available - 1 where id = p_tier_id;
    if v_has_previous then
      perform private.move_seat(p_event_id, v_previous_tier, 1);
    end if;
  end if;

  insert into public.reservations (
    event_id, user_id, organizer_id, user_name, user_email,
    event_title, event_starts_at, event_location,
    status, reserved_at, tier_id, tier_name,
    price_paid, amount_due, currency, payment_status, hold_expires_at
  )
  values (
    p_event_id, p_user_id, v_event.organizer_id, v_profile.name, v_profile.email,
    v_event.title, v_event.starts_at, v_event.location,
    'pending', now(), p_tier_id, v_tier.name,
    0, v_tier.price, v_event.currency, 'pending', v_expires_at + v_grace
  )
  on conflict on constraint reservations_one_per_event do update
  set organizer_id = excluded.organizer_id,
      user_name = excluded.user_name,
      user_email = excluded.user_email,
      event_title = excluded.event_title,
      event_starts_at = excluded.event_starts_at,
      event_location = excluded.event_location,
      status = 'pending',
      reserved_at = now(),
      cancelled_at = null,
      cancelled_by = null,
      tier_id = excluded.tier_id,
      tier_name = excluded.tier_name,
      price_paid = 0,
      amount_due = excluded.amount_due,
      currency = excluded.currency,
      payment_status = 'pending',
      hold_expires_at = excluded.hold_expires_at,
      checkout_session_id = null,
      checkout_url = null,
      payment_intent_id = null,
      refund_id = null,
      reminder_sent_at = null
  returning * into v_res;

  perform private.audit('payment.seat_held', jsonb_build_object(
    'reservation_id', v_res.id, 'tier_id', p_tier_id, 'amount', v_tier.price, 'currency', v_event.currency));

  return jsonb_build_object(
    'reservation_id', v_res.id,
    'reused_url', null,
    'price', v_tier.price,
    'currency', v_event.currency,
    'tier_name', v_tier.name,
    'event_title', v_event.title,
    'email', v_profile.email,
    'expires_at', v_expires_at
  );
end;
$$;

create function public.payments_attach_session(p_reservation_id uuid, p_session_id text, p_url text)
returns void
language sql
security definer
set search_path = ''
as $$
  update public.reservations
  set checkout_session_id = p_session_id, checkout_url = p_url
  where id = p_reservation_id and status = 'pending';
$$;

-- `pending` → `cancelled`, seat given back. False when nothing was held
-- (already confirmed, already released): safe to call twice.
create function public.payments_release_hold(p_reservation_id uuid, p_outcome public.payment_status)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_event_id uuid;
  v_res public.reservations%rowtype;
begin
  select r.event_id into v_event_id from public.reservations r where r.id = p_reservation_id;
  if v_event_id is not null then
    perform 1 from public.events e where e.id = v_event_id for update;
  end if;
  select * into v_res from public.reservations r where r.id = p_reservation_id for update;
  if not found or v_res.status <> 'pending' then
    return false;
  end if;

  perform private.move_seat(v_res.event_id, v_res.tier_id, 1);
  update public.reservations
  set status = 'cancelled', cancelled_at = now(), cancelled_by = 'system',
      payment_status = p_outcome, hold_expires_at = null, checkout_url = null
  where id = p_reservation_id;

  perform private.audit('payment.hold_released', jsonb_build_object(
    'reservation_id', p_reservation_id, 'outcome', p_outcome));
  return true;
end;
$$;

-- `pending` from the caller's own point of view (the buyer gives up).
create function public.payments_release_own_hold(p_user_id uuid, p_event_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_res public.reservations%rowtype;
  v_released boolean;
begin
  select * into v_res from public.reservations r
  where r.event_id = p_event_id and r.user_id = p_user_id;
  if not found then
    return jsonb_build_object('released', false);
  end if;
  v_released := public.payments_release_hold(v_res.id, 'cancelled');
  return jsonb_build_object('released', v_released, 'session_id', v_res.checkout_session_id);
end;
$$;

-- Confirms a paid reservation (webhook). Outcomes:
--  confirmed — the held seat becomes a ticket, or a late payment whose hold
--              was released finds a seat again;
--  already   — replayed webhook, nothing to do;
--  missing   — unknown reservation;
--  refund    — the hold was released and no seat is left, or the event is
--              gone: the caller refunds at once. Never charged without a
--              ticket.
create function public.payments_fulfill(
  p_reservation_id uuid,
  p_payment_intent_id text,
  p_amount integer,
  p_currency text,
  p_session_id text
)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_event_id uuid;
  v_res public.reservations%rowtype;
  v_event public.events%rowtype;
  v_seat_left boolean := false;
begin
  select r.event_id into v_event_id from public.reservations r where r.id = p_reservation_id;
  if v_event_id is not null then
    select * into v_event from public.events e where e.id = v_event_id for update;
  end if;
  select * into v_res from public.reservations r where r.id = p_reservation_id for update;
  if not found then
    return 'missing';
  end if;
  if v_res.status = 'confirmed' then
    return 'already';
  end if;

  if v_res.status = 'cancelled' then
    if v_event.id is not null and v_event.starts_at > now() then
      if v_res.tier_id is not null then
        select t.available > 0 into v_seat_left from public.event_tiers t where t.id = v_res.tier_id;
      else
        v_seat_left := v_event.available_places > 0;
      end if;
    end if;
    if not coalesce(v_seat_left, false) then
      update public.reservations
      set payment_intent_id = p_payment_intent_id, checkout_session_id = p_session_id
      where id = p_reservation_id;
      return 'refund';
    end if;
    perform private.move_seat(v_res.event_id, v_res.tier_id, -1);
  end if;

  update public.reservations
  set status = 'confirmed',
      cancelled_at = null,
      cancelled_by = null,
      price_paid = p_amount,
      currency = upper(p_currency)::public.currency_code,
      payment_status = 'paid',
      payment_intent_id = p_payment_intent_id,
      checkout_session_id = p_session_id,
      reserved_at = now(),
      hold_expires_at = null,
      checkout_url = null
  where id = p_reservation_id;

  perform private.notify(
    v_res.user_id, 'paymentConfirmed', 'Paiement confirmé',
    'Votre billet ' || coalesce(v_res.tier_name || ' ', '') || 'pour « ' || v_res.event_title || ' » est prêt.',
    v_res.event_id, v_res.id);
  perform private.audit('payment.confirmed', jsonb_build_object(
    'reservation_id', p_reservation_id, 'amount', p_amount, 'currency', upper(p_currency),
    'payment_intent_id', p_payment_intent_id, 'late', v_res.status = 'cancelled'));
  return 'confirmed';
end;
$$;

-- A payment that found no seat was refunded by the webhook.
create function public.payments_mark_refunded(
  p_reservation_id uuid,
  p_payment_intent_id text,
  p_refund_id text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_res public.reservations%rowtype;
begin
  update public.reservations
  set payment_status = 'refunded', payment_intent_id = p_payment_intent_id, refund_id = p_refund_id
  where id = p_reservation_id
  returning * into v_res;
  if found then
    perform private.notify(
      v_res.user_id, 'paymentRefunded', 'Paiement remboursé',
      'Plus de place disponible pour « ' || v_res.event_title || ' » au moment du paiement : '
        || 'vous êtes intégralement remboursé.',
      v_res.event_id, v_res.id);
  end if;
  perform private.audit('payment.refunded', jsonb_build_object(
    'reservation_id', p_reservation_id, 'refund_id', p_refund_id, 'context', 'no_seat'));
end;
$$;

-- The buyer asks for a refund (ReservationPolicy.canRefund): a paid, active
-- ticket, before the event starts. Returns what Stripe needs.
create function public.payments_begin_refund(p_user_id uuid, p_event_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_res public.reservations%rowtype;
begin
  select * into v_res from public.reservations r
  where r.event_id = p_event_id and r.user_id = p_user_id;
  if not found then
    perform private.fail(404, 'notFound', 'Réservation introuvable.');
  end if;
  if v_res.status <> 'confirmed' or v_res.price_paid <= 0 then
    perform private.fail(409, 'reservationNotActive', 'Ce billet n''est pas un billet payé en cours.');
  end if;
  if v_res.event_starts_at <= now() then
    perform private.fail(409, 'eventAlreadyStarted', 'L''événement a commencé : le billet n''est plus remboursable.');
  end if;
  if v_res.payment_intent_id is null then
    perform private.fail(409, 'actionRefused', 'Paiement introuvable : contactez le support.');
  end if;
  return jsonb_build_object('reservation_id', v_res.id, 'payment_intent_id', v_res.payment_intent_id);
end;
$$;

-- Stripe has refunded: the ticket is cancelled and the seat goes back on
-- sale. The refund always happens before the seat is released.
create function public.payments_complete_refund(p_reservation_id uuid, p_refund_id text)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_event_id uuid;
  v_res public.reservations%rowtype;
begin
  select r.event_id into v_event_id from public.reservations r where r.id = p_reservation_id;
  if v_event_id is not null then
    perform 1 from public.events e where e.id = v_event_id for update;
  end if;
  select * into v_res from public.reservations r where r.id = p_reservation_id for update;
  if not found or v_res.status <> 'confirmed' then
    return false;
  end if;

  perform private.move_seat(v_res.event_id, v_res.tier_id, 1);
  update public.reservations
  set status = 'cancelled', cancelled_at = now(), cancelled_by = 'participant',
      payment_status = 'refunded', refund_id = p_refund_id
  where id = p_reservation_id;

  perform private.audit('payment.refunded', jsonb_build_object(
    'reservation_id', p_reservation_id, 'refund_id', p_refund_id, 'context', 'participant'));
  return true;
end;
$$;

-- A queued refund (moderation, account deletion) went through.
create function public.payments_refund_settled(p_reservation_id uuid, p_refund_id text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.reservations
  set payment_status = 'refunded', refund_id = p_refund_id
  where id = p_reservation_id;
  perform private.audit('payment.refunded', jsonb_build_object(
    'reservation_id', p_reservation_id, 'refund_id', p_refund_id, 'context', 'queue'));
end;
$$;

-- Safety net when Stripe's `checkout.session.expired` never arrives.
create function private.release_expired_holds(p_now timestamptz default now())
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id uuid;
  v_released integer := 0;
begin
  for v_id in
    select r.id from public.reservations r
    where r.status = 'pending' and r.hold_expires_at <= p_now
    order by r.hold_expires_at
    limit 500
  loop
    if public.payments_release_hold(v_id, 'expired') then
      v_released := v_released + 1;
    end if;
  end loop;
  return v_released;
end;
$$;
