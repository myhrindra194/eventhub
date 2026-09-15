-- =============================================================================
--  EventHub · 13 · One account, two spaces (the Eventbrite / Airbnb model)
-- =============================================================================
--  Before: the role was chosen once at sign-up and a participant could never
--  organize, an organizer never book. Large event platforms do otherwise:
--  everyone signs up as a guest, "hosting" is switched on later, and a host
--  still books other people's events.
--
--   * every account starts as a participant — sign-up metadata no longer
--     chooses the role, and a client cannot insert an organizer profile;
--   * public.become_organizer() turns the organizer space on (verified email
--     required), one way only: an organizer never goes back, their events
--     and sales depend on it;
--   * every account may book, queue, buy and review — except at an event it
--     runs (owner or co-organizer).
-- =============================================================================

-- ------------------------------------------------------------ profiles ---

-- New profiles are participants, whatever the client or the metadata say.
create or replace function private.profiles_before_insert()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_email text;
begin
  select u.email into v_email from auth.users u where u.id = new.id;
  if v_email is null then
    perform private.fail(422, 'validation', 'Compte d''authentification introuvable.');
  end if;
  new.email := v_email;
  new.name := btrim(new.name);
  new.bio := nullif(btrim(coalesce(new.bio, '')), '');
  new.role := 'participant';
  new.suspended_at := null;
  new.welcomed_at := null;
  new.created_at := now();
  new.updated_at := now();
  return new;
end;
$$;

-- The role still never changes by an update — except the one upgrade that
-- become_organizer performs.
create or replace function private.profiles_before_update()
returns trigger
language plpgsql
as $$
begin
  if new.role is distinct from old.role and not (
    old.role = 'participant'
    and new.role = 'organizer'
    and coalesce(current_setting('eventhub.role_upgrade', true), '') = 'on'
  ) then
    perform private.fail(403, 'actionRefused', 'Le rôle d''un compte ne se modifie pas ainsi.');
  end if;
  if new.id is distinct from old.id or new.created_at is distinct from old.created_at then
    perform private.fail(403, 'actionRefused', 'Ces informations ne se modifient pas.');
  end if;
  if new.email is distinct from old.email
     and coalesce(current_setting('eventhub.email_sync', true), '') <> 'on' then
    perform private.fail(403, 'actionRefused', 'L''email se change depuis la sécurité du compte.');
  end if;
  new.name := btrim(new.name);
  new.bio := nullif(btrim(coalesce(new.bio, '')), '');
  return new;
end;
$$;

-- Sign-up creates a participant from the name alone.
create or replace function private.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_name text := btrim(coalesce(new.raw_user_meta_data ->> 'name', new.raw_user_meta_data ->> 'full_name', ''));
begin
  if new.email is not null and char_length(v_name) between 2 and 80 then
    insert into public.profiles (id, name, email, role)
    values (new.id, v_name, new.email, 'participant')
    on conflict (id) do nothing;
  end if;
  return null;
end;
$$;

-- "Devenir organisateur": the public page is created, the role mirrored into
-- the token, and the answer says whether anything changed.
create function public.become_organizer()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid constant uuid := private.require_user();
  v_profile public.profiles%rowtype;
begin
  select * into v_profile from public.profiles p where p.id = v_uid for update;
  if not found then
    perform private.fail(404, 'notFound', 'Complétez votre profil d''abord.');
  end if;
  if v_profile.role = 'organizer' then
    return jsonb_build_object('organizer', true, 'changed', false);
  end if;
  if not private.is_verified() then
    perform private.fail(403, 'emailNotVerified', 'Confirmez votre adresse email pour organiser des événements.');
  end if;

  perform set_config('eventhub.role_upgrade', 'on', true);
  update public.profiles set role = 'organizer' where id = v_uid;
  perform set_config('eventhub.role_upgrade', 'off', true);

  insert into public.organizers (id, name, bio, photo_url, member_since)
  values (v_uid, v_profile.name, coalesce(v_profile.bio, ''), v_profile.photo_url, v_profile.created_at)
  on conflict (id) do nothing;

  update auth.users
  set raw_app_meta_data = coalesce(raw_app_meta_data, '{}'::jsonb) || jsonb_build_object('role', 'organizer')
  where id = v_uid;

  perform private.audit('account.became_organizer', jsonb_build_object('user_id', v_uid));
  return jsonb_build_object('organizer', true, 'changed', true);
end;
$$;

revoke execute on function public.become_organizer() from public, anon;
grant execute on function public.become_organizer() to authenticated;

-- A review comes from someone who attended — any account, not the team.
create or replace function private.can_review(p_event_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (select 1 from public.profiles p where p.id = auth.uid())
    and not private.is_event_team(p_event_id)
    and private.is_verified()
    and exists (
      select 1 from public.reservations r
      where r.event_id = p_event_id
        and r.user_id = auth.uid()
        and r.status = 'confirmed'
        and r.event_starts_at < now()
    );
$$;

-- ------------------------------------------------ booking for everyone ---

create or replace function public.reserve_seat(p_event_id uuid, p_tier_id uuid default null)
returns public.reservations
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid constant uuid := private.require_user();
  v_profile public.profiles%rowtype;
  v_event public.events%rowtype;
  v_tier public.event_tiers%rowtype;
  v_existing public.reservations%rowtype;
  v_result public.reservations%rowtype;
begin
  select * into v_profile from public.profiles p where p.id = v_uid;
  if not found then
    perform private.fail(403, 'actionRefused', 'Complétez votre profil pour réserver.');
  end if;
  perform private.throttle('reserve:' || v_uid::text, 20, interval '1 minute');

  select * into v_event from public.events e where e.id = p_event_id for update;
  if not found then
    perform private.fail(404, 'notFound', 'Cet événement n''existe plus.');
  end if;
  -- Every account can book, but never a seat at an event it runs.
  if private.is_event_team(p_event_id) then
    perform private.fail(409, 'actionRefused', 'Vous organisez cet événement : vous ne pouvez pas y réserver de place.');
  end if;

  select * into v_existing
  from public.reservations r
  where r.event_id = p_event_id and r.user_id = v_uid
  for update;
  if found and v_existing.status = 'confirmed' then
    perform private.fail(409, 'alreadyReserved', 'Vous avez déjà réservé cet événement.');
  end if;
  if found and v_existing.status = 'pending' then
    perform private.fail(409, 'paymentPending',
      'Un paiement est en cours pour cet événement : terminez-le ou annulez-le d''abord.');
  end if;
  if v_event.starts_at <= now() then
    perform private.fail(409, 'eventAlreadyStarted', 'Cet événement a déjà commencé.');
  end if;
  if v_event.available_places <= 0 then
    perform private.fail(409, 'eventFull', 'Cet événement est complet.');
  end if;

  if exists (select 1 from public.event_tiers t where t.event_id = p_event_id) then
    if p_tier_id is null then
      perform private.fail(409, 'tierRequired', 'Choisissez un type de billet.');
    end if;
    select * into v_tier from public.event_tiers t
    where t.id = p_tier_id and t.event_id = p_event_id
    for update;
    if not found then
      perform private.fail(409, 'tierRequired', 'Ce type de billet n''existe plus.');
    end if;
    if v_tier.price > 0 then
      perform private.fail(409, 'paymentRequired',
        format('Le billet « %s » est payant : passez au paiement.', v_tier.name));
    end if;
    if v_tier.available <= 0 then
      perform private.fail(409, 'tierSoldOut', format('Le billet « %s » est complet.', v_tier.name));
    end if;
    update public.event_tiers set available = available - 1 where id = p_tier_id;
  else
    if p_tier_id is not null then
      perform private.fail(409, 'tierRequired', 'Cet événement n''a pas de types de billets.');
    end if;
    update public.events set available_places = available_places - 1 where id = p_event_id;
  end if;

  -- A re-booking after a cancellation reuses the row: new booking date, the
  -- previous cancellation and payment traces cleared (kept in the audit).
  insert into public.reservations (
    event_id, user_id, organizer_id, user_name, user_email,
    event_title, event_starts_at, event_location,
    status, reserved_at, tier_id, tier_name
  )
  values (
    p_event_id, v_uid, v_event.organizer_id, v_profile.name, v_profile.email,
    v_event.title, v_event.starts_at, v_event.location,
    'confirmed', now(), v_tier.id, v_tier.name
  )
  on conflict on constraint reservations_one_per_event do update
  set organizer_id = excluded.organizer_id,
      user_name = excluded.user_name,
      user_email = excluded.user_email,
      event_title = excluded.event_title,
      event_starts_at = excluded.event_starts_at,
      event_location = excluded.event_location,
      status = 'confirmed',
      reserved_at = now(),
      cancelled_at = null,
      cancelled_by = null,
      tier_id = excluded.tier_id,
      tier_name = excluded.tier_name,
      price_paid = 0,
      amount_due = null,
      currency = null,
      payment_status = null,
      checkout_session_id = null,
      checkout_url = null,
      hold_expires_at = null,
      payment_intent_id = null,
      refund_id = null,
      reminder_sent_at = null
  returning * into v_result;

  return v_result;
end;
$$;

create or replace function public.join_waitlist(p_event_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid constant uuid := private.require_user();
  v_profile public.profiles%rowtype;
  v_event public.events%rowtype;
begin
  select * into v_profile from public.profiles p where p.id = v_uid;
  if not found then
    perform private.fail(403, 'actionRefused', 'Complétez votre profil pour rejoindre la liste d''attente.');
  end if;
  select * into v_event from public.events e where e.id = p_event_id;
  if not found then
    perform private.fail(404, 'notFound', 'Cet événement n''existe plus.');
  end if;
  if private.is_event_team(p_event_id) then
    perform private.fail(409, 'actionRefused', 'Vous organisez cet événement : pas de liste d''attente pour vous.');
  end if;
  if v_event.starts_at <= now() then
    perform private.fail(409, 'eventAlreadyStarted', 'Cet événement a déjà commencé.');
  end if;
  if v_event.available_places > 0 then
    perform private.fail(409, 'waitlistNotAvailable', 'Des places sont disponibles : réservez directement.');
  end if;
  if exists (
    select 1 from public.reservations r
    where r.event_id = p_event_id and r.user_id = v_uid and r.status in ('confirmed', 'pending')
  ) then
    perform private.fail(409, 'alreadyReserved', 'Vous avez déjà une place pour cet événement.');
  end if;

  insert into public.waitlist_entries (event_id, user_id, user_name)
  values (p_event_id, v_uid, v_profile.name)
  on conflict (event_id, user_id) do nothing;
end;
$$;

create or replace function public.payments_hold_seat(
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
  if not found then
    perform private.fail(403, 'actionRefused', 'Complétez votre profil pour acheter un billet.');
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
  if v_event.organizer_id = p_user_id or exists (
    select 1 from public.event_staff s where s.event_id = p_event_id and s.user_id = p_user_id
  ) then
    perform private.fail(409, 'actionRefused', 'Vous organisez cet événement : vous ne pouvez pas y acheter de billet.');
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
