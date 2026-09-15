-- =============================================================================
--  EventHub · 5/8 · Application API
--  The RPCs the Flutter app calls (`supabase.rpc(...)`). Each one is a single
--  transaction that re-checks every rule of the matching domain policy in
--  lib/features/*/domain — the app checks first for a fast, friendly answer,
--  the database decides.
--
--  Locking order, everywhere: event row → reservation row → ticket type row.
--  One order means no deadlock between a booking, a cancellation, a checkout
--  and an edit of the same event.
-- =============================================================================

-- ============================================================= helpers ===

-- Gives back (+1) or takes (-1) a seat, in the ticket type when the event
-- has types (the event total follows through its trigger), otherwise on
-- the event itself. Bounded, so a replayed release can never overflow.
create function private.move_seat(p_event_id uuid, p_tier_id uuid, p_delta integer)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if p_event_id is null then
    return;
  end if;
  if exists (select 1 from public.event_tiers t where t.event_id = p_event_id) then
    update public.event_tiers
    set available = least(capacity, greatest(0, available + p_delta))
    where id = p_tier_id and event_id = p_event_id;
  else
    update public.events
    set available_places = least(capacity, greatest(0, available_places + p_delta))
    where id = p_event_id;
  end if;
end;
$$;

create function private.require_user()
returns uuid
language plpgsql
stable
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    perform private.fail(401, 'notSignedIn', 'Vous devez être connecté.');
  end if;
  return v_uid;
end;
$$;

-- ============================================================= devices ===

-- A token belongs to the account signed in on the device right now: it is
-- taken away from any other account first.
create function public.register_device(
  p_device_id text,
  p_token text,
  p_platform public.device_platform,
  p_locale text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid constant uuid := private.require_user();
begin
  perform private.throttle('device:' || v_uid::text, 20, interval '1 minute');
  delete from public.devices where token = p_token and user_id <> v_uid;
  insert into public.devices (user_id, device_id, token, platform, locale, updated_at)
  values (v_uid, p_device_id, p_token, p_platform, nullif(btrim(coalesce(p_locale, '')), ''), now())
  on conflict (user_id, device_id) do update
  set token = excluded.token, platform = excluded.platform, locale = excluded.locale, updated_at = now();
end;
$$;

-- ============================================================== events ===

-- Creates or edits an event and its ticket types in one transaction.
--
-- Payload (JSON): id? · title · description · category · starts_at ·
-- location · image_url? · capacity (without types) · currency? ·
-- tiers: [{id?, name, price, capacity}] (0..6, in display order).
--
-- Mirrors EventDraft.validate and TierPlanner.apply:
--  * a type keeps what it sold: its capacity cannot go below it, and a type
--    that sold cannot be removed;
--  * once seats are sold, the mode (single capacity / types) is locked;
--  * the currency is locked once a payment exists.
create function public.save_event(p_event jsonb)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid constant uuid := private.require_user();
  v_id uuid;
  v_event public.events%rowtype;
  v_errors jsonb := '{}'::jsonb;
  v_title text := btrim(coalesce(p_event ->> 'title', ''));
  v_description text := btrim(coalesce(p_event ->> 'description', ''));
  v_location text := btrim(coalesce(p_event ->> 'location', ''));
  v_image text := nullif(btrim(coalesce(p_event ->> 'image_url', '')), '');
  v_category public.event_category;
  v_starts_at timestamptz;
  v_capacity integer;
  v_currency public.currency_code;
  v_tiers jsonb := coalesce(p_event -> 'tiers', '[]'::jsonb);
  v_tier jsonb;
  v_tier_count integer;
  v_names text[] := '{}';
  v_name text;
  v_price integer;
  v_tier_capacity integer;
  v_tiers_valid boolean := true;
  v_has_paid boolean := false;
  v_taken integer;
  v_had_tiers boolean;
  v_current public.event_tiers%rowtype;
  v_kept uuid[] := '{}';
  v_tier_id uuid;
  v_position integer := 0;
begin
  if not private.is_organizer() then
    perform private.fail(403, 'notEventOwner', 'Seul un organisateur publie des événements.');
  end if;
  perform private.throttle('save_event:' || v_uid::text, 30, interval '1 minute');

  if nullif(p_event ->> 'id', '') is not null then
    v_id := private.try_uuid(p_event ->> 'id');
    if v_id is null then
      perform private.fail(404, 'notFound', 'Événement introuvable.');
    end if;
  end if;

  -- ---- fields -----------------------------------------------------------
  if char_length(v_title) not between 3 and 120 then
    v_errors := v_errors || jsonb_build_object('title', 'Entre 3 et 120 caractères.');
  end if;
  if char_length(v_description) not between 1 and 5000 then
    v_errors := v_errors || jsonb_build_object('description', 'Décrivez l''événement (5 000 caractères au plus).');
  end if;
  if char_length(v_location) not between 1 and 200 then
    v_errors := v_errors || jsonb_build_object('location', 'Indiquez le lieu (200 caractères au plus).');
  end if;
  if v_image is not null and (v_image !~ '^https://' or char_length(v_image) > 2048) then
    v_errors := v_errors || jsonb_build_object('imageUrl', 'Image invalide.');
  end if;
  begin
    v_category := (p_event ->> 'category')::public.event_category;
  exception when others then
    v_category := null;
  end;
  if v_category is null then
    v_errors := v_errors || jsonb_build_object('category', 'Choisissez une catégorie.');
  end if;
  begin
    v_starts_at := (p_event ->> 'starts_at')::timestamptz;
  exception when others then
    v_starts_at := null;
  end;
  if v_starts_at is null then
    v_errors := v_errors || jsonb_build_object('startsAt', 'Date invalide.');
  end if;

  -- ---- ticket types -----------------------------------------------------
  if jsonb_typeof(v_tiers) <> 'array' then
    v_errors := v_errors || jsonb_build_object('tiers', 'Types de billets invalides.');
    v_tiers := '[]'::jsonb;
  end if;
  v_tier_count := jsonb_array_length(v_tiers);

  if v_tier_count > 6 then
    v_errors := v_errors || jsonb_build_object('tiers', '6 types de billets au plus.');
  elsif v_tier_count > 0 then
    v_capacity := 0;
    for v_tier in select value from jsonb_array_elements(v_tiers) loop
      v_name := btrim(coalesce(v_tier ->> 'name', ''));
      v_price := case when v_tier -> 'price' is null or v_tier -> 'price' = 'null'::jsonb
                      then 0 else private.json_int(v_tier -> 'price') end;
      v_tier_capacity := private.json_int(v_tier -> 'capacity');
      if char_length(v_name) not between 1 and 60
         or lower(v_name) = any (v_names)
         or coalesce(v_tier_capacity, 0) not between 1 and 100000
         or v_price is null or v_price not between 0 and 100000000 then
        v_tiers_valid := false;
      else
        v_names := v_names || lower(v_name);
        v_capacity := v_capacity + v_tier_capacity;
        v_has_paid := v_has_paid or v_price > 0;
      end if;
    end loop;
    if not v_tiers_valid then
      v_errors := v_errors || jsonb_build_object('tiers', 'Chaque type a un nom unique, au moins une place et un prix valide.');
    elsif v_capacity > 100000 then
      v_errors := v_errors || jsonb_build_object('tiers', 'Capacité totale : 100 000 places au plus.');
    end if;
  else
    v_capacity := private.json_int(p_event -> 'capacity');
    if coalesce(v_capacity, 0) not between 1 and 100000 then
      v_errors := v_errors || jsonb_build_object('capacity', 'Entre 1 et 100 000 places.');
    end if;
  end if;

  if v_has_paid then
    begin
      v_currency := (p_event ->> 'currency')::public.currency_code;
    exception when others then
      v_currency := null;
    end;
    if v_currency is null then
      v_errors := v_errors || jsonb_build_object('currency', 'Choisissez la devise des billets payants.');
    end if;
  end if;

  if v_errors <> '{}'::jsonb then
    perform private.fail_validation(v_errors);
  end if;

  -- ---- create -----------------------------------------------------------
  if v_id is null then
    if not private.is_verified() then
      perform private.fail(403, 'emailNotVerified', 'Confirmez votre adresse email avant de publier.');
    end if;
    if v_starts_at <= now() then
      perform private.fail_validation(jsonb_build_object('startsAt', 'La date doit être dans le futur.'));
    end if;

    insert into public.events (
      organizer_id, organizer_name, title, description, category, starts_at,
      location, image_url, capacity, available_places, currency
    )
    select v_uid, p.name, v_title, v_description, v_category, v_starts_at,
           v_location, v_image, v_capacity, v_capacity, v_currency
    from public.profiles p
    where p.id = v_uid
    returning * into v_event;

    for v_tier in select value from jsonb_array_elements(v_tiers) loop
      v_tier_capacity := private.json_int(v_tier -> 'capacity');
      insert into public.event_tiers (event_id, name, price, capacity, available, position)
      values (
        v_event.id,
        btrim(v_tier ->> 'name'),
        coalesce(private.json_int(v_tier -> 'price'), 0),
        v_tier_capacity,
        v_tier_capacity,
        v_position
      );
      v_position := v_position + 1;
    end loop;

    perform private.audit('event.created', jsonb_build_object('event_id', v_event.id, 'tiers', v_tier_count));
    return v_event.id;
  end if;

  -- ---- update -----------------------------------------------------------
  select * into v_event from public.events e where e.id = v_id for update;
  if not found then
    perform private.fail(404, 'notFound', 'Événement introuvable.');
  end if;
  if not private.is_event_team(v_id) then
    perform private.fail(403, 'notEventOwner', 'Vous ne gérez pas cet événement.');
  end if;

  -- Seats sold include seats held on the payment page.
  v_taken := v_event.capacity - v_event.available_places;
  v_had_tiers := exists (select 1 from public.event_tiers t where t.event_id = v_id);

  if v_event.currency is distinct from v_currency and exists (
    select 1 from public.reservations r
    where r.event_id = v_id and (r.price_paid > 0 or r.status = 'pending')
  ) then
    perform private.fail(409, 'tiersLocked', 'Des billets ont été payés : la devise et les billets payants restent en place.');
  end if;

  if v_tier_count = 0 then
    if v_had_tiers then
      if v_taken > 0 then
        perform private.fail(409, 'tiersLocked', 'Des places ont été vendues : les types de billets restent en place.');
      end if;
      delete from public.event_tiers where event_id = v_id;
    end if;
    if v_capacity < v_taken then
      perform private.fail(409, 'capacityBelowReservations',
        format('La capacité ne peut pas descendre sous les %s places déjà réservées.', v_taken));
    end if;
    update public.events
    set title = v_title, description = v_description, category = v_category,
        starts_at = v_starts_at, location = v_location, image_url = v_image,
        capacity = v_capacity, available_places = v_capacity - v_taken, currency = null
    where id = v_id;
  else
    if not v_had_tiers and v_taken > 0 then
      perform private.fail(409, 'tiersLocked', 'Des places ont été vendues : l''événement garde sa capacité unique.');
    end if;

    for v_tier in select value from jsonb_array_elements(v_tiers) loop
      v_tier_id := private.try_uuid(v_tier ->> 'id');
      if v_tier_id is not null and exists (
        select 1 from public.event_tiers t where t.id = v_tier_id and t.event_id = v_id
      ) then
        v_kept := v_kept || v_tier_id;
      end if;
    end loop;

    if exists (
      select 1 from public.event_tiers t
      where t.event_id = v_id and not (t.id = any (v_kept)) and t.capacity > t.available
    ) then
      perform private.fail(409, 'tiersLocked', 'Un type de billet déjà vendu ne peut pas être supprimé.');
    end if;
    delete from public.event_tiers t where t.event_id = v_id and not (t.id = any (v_kept));

    -- Park the kept names so a swap ("VIP" ↔ "Standard") never collides on
    -- the unique name index halfway through.
    update public.event_tiers set name = '~' || id::text where event_id = v_id;

    for v_tier in select value from jsonb_array_elements(v_tiers) loop
      v_tier_id := private.try_uuid(v_tier ->> 'id');
      v_name := btrim(v_tier ->> 'name');
      v_price := coalesce(private.json_int(v_tier -> 'price'), 0);
      v_tier_capacity := private.json_int(v_tier -> 'capacity');

      if v_tier_id is not null and v_tier_id = any (v_kept) then
        select * into v_current from public.event_tiers t where t.id = v_tier_id for update;
        if v_tier_capacity < v_current.capacity - v_current.available then
          perform private.fail(409, 'capacityBelowReservations',
            format('« %s » : %s places déjà vendues.', v_name, v_current.capacity - v_current.available));
        end if;
        update public.event_tiers
        set name = v_name, price = v_price, capacity = v_tier_capacity,
            available = v_tier_capacity - (v_current.capacity - v_current.available),
            position = v_position
        where id = v_tier_id;
      else
        insert into public.event_tiers (event_id, name, price, capacity, available, position)
        values (v_id, v_name, v_price, v_tier_capacity, v_tier_capacity, v_position);
      end if;
      v_position := v_position + 1;
    end loop;

    update public.events
    set title = v_title, description = v_description, category = v_category,
        starts_at = v_starts_at, location = v_location, image_url = v_image,
        currency = v_currency
    where id = v_id;
  end if;

  if v_event.image_url is distinct from v_image then
    perform private.enqueue_storage_delete_url(v_event.image_url);
  end if;
  perform private.audit('event.updated', jsonb_build_object('event_id', v_id, 'tiers', v_tier_count));
  return v_id;
end;
$$;

-- Deleting is the owner's call, and only while no seat is taken.
create function public.delete_event(p_event_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid constant uuid := private.require_user();
  v_event public.events%rowtype;
begin
  select * into v_event from public.events e where e.id = p_event_id for update;
  if not found then
    perform private.fail(404, 'notFound', 'Événement introuvable.');
  end if;
  if v_event.organizer_id <> v_uid then
    perform private.fail(403, 'notEventOwner', 'Seul l''organisateur principal supprime l''événement.');
  end if;
  if v_event.capacity - v_event.available_places > 0 then
    perform private.fail(409, 'eventHasReservations',
      'Des places sont réservées : l''événement ne peut pas être supprimé.');
  end if;
  delete from public.events where id = p_event_id;
  perform private.enqueue_storage_delete_url(v_event.image_url);
  perform private.audit('event.deleted', jsonb_build_object('event_id', p_event_id));
end;
$$;

-- ======================================================== reservations ===

-- A free seat (ReservationPolicy.canReserve). A paid type goes through the
-- `payments-checkout` Edge Function instead.
create function public.reserve_seat(p_event_id uuid, p_tier_id uuid default null)
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
  if not found or v_profile.role <> 'participant' then
    perform private.fail(403, 'actionRefused', 'Seul un participant peut réserver.');
  end if;
  perform private.throttle('reserve:' || v_uid::text, 20, interval '1 minute');

  select * into v_event from public.events e where e.id = p_event_id for update;
  if not found then
    perform private.fail(404, 'notFound', 'Cet événement n''existe plus.');
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

-- A free seat given back (ReservationPolicy.canCancel). A paid ticket is
-- refunded by the `payments-refund` Edge Function.
create function public.cancel_reservation(p_reservation_id uuid)
returns public.reservations
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid constant uuid := private.require_user();
  v_res public.reservations%rowtype;
begin
  select * into v_res from public.reservations r where r.id = p_reservation_id;
  if not found then
    perform private.fail(404, 'notFound', 'Réservation introuvable.');
  end if;
  if v_res.user_id is distinct from v_uid then
    perform private.fail(403, 'notReservationOwner', 'Cette réservation ne vous appartient pas.');
  end if;

  if v_res.event_id is not null then
    perform 1 from public.events e where e.id = v_res.event_id for update;
  end if;
  select * into v_res from public.reservations r where r.id = p_reservation_id for update;

  if v_res.status = 'pending' then
    perform private.fail(409, 'paymentPending', 'Paiement en cours : abandonnez-le depuis l''écran de paiement.');
  end if;
  if v_res.status <> 'confirmed' then
    perform private.fail(409, 'reservationNotActive', 'Cette réservation est déjà annulée.');
  end if;
  if v_res.price_paid > 0 then
    perform private.fail(409, 'refundRequired', 'Billet payé : l''annulation passe par le remboursement.');
  end if;

  perform private.move_seat(v_res.event_id, v_res.tier_id, 1);

  update public.reservations
  set status = 'cancelled', cancelled_at = now(), cancelled_by = 'participant'
  where id = p_reservation_id
  returning * into v_res;
  return v_res;
end;
$$;

-- ============================================================ waitlist ===

create function public.join_waitlist(p_event_id uuid)
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
  if not found or v_profile.role <> 'participant' then
    perform private.fail(403, 'actionRefused', 'Seul un participant rejoint une liste d''attente.');
  end if;
  select * into v_event from public.events e where e.id = p_event_id;
  if not found then
    perform private.fail(404, 'notFound', 'Cet événement n''existe plus.');
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

create function public.leave_waitlist(p_event_id uuid)
returns void
language sql
security definer
set search_path = ''
as $$
  delete from public.waitlist_entries
  where event_id = p_event_id and user_id = private.require_user();
$$;

-- ============================================================ check-in ===

-- The door verdict, decided and recorded atomically: two scanners reading
-- the same ticket at the same instant produce one `admitted` and one
-- `alreadyCheckedIn`, never two admissions.
--
-- Returns {status, reservation_id?, user_name?, tier_name?, scanned_at?}
-- with status ∈ notFound · wrongEvent · unpaid · cancelled ·
-- alreadyCheckedIn · admitted (CheckInStatus in the app).
create function public.check_in_ticket(p_event_id uuid, p_reservation_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid constant uuid := private.require_user();
  v_res public.reservations%rowtype;
  v_scanned_at timestamptz;
  v_ticket jsonb;
begin
  if not private.is_event_team(p_event_id) then
    perform private.fail(403, 'notEventOwner', 'Seule l''équipe de l''événement contrôle les entrées.');
  end if;
  perform private.throttle('checkin:' || v_uid::text, 240, interval '1 minute');

  select * into v_res from public.reservations r where r.id = p_reservation_id;
  if not found then
    return jsonb_build_object('status', 'notFound');
  end if;
  if v_res.event_id is distinct from p_event_id then
    return jsonb_build_object('status', 'wrongEvent');
  end if;

  v_ticket := jsonb_build_object(
    'reservation_id', v_res.id,
    'user_name', v_res.user_name,
    'tier_name', v_res.tier_name,
    'price_paid', v_res.price_paid,
    'currency', v_res.currency
  );
  if v_res.status = 'pending' then
    return v_ticket || jsonb_build_object('status', 'unpaid');
  end if;
  if v_res.status = 'cancelled' then
    return v_ticket || jsonb_build_object('status', 'cancelled');
  end if;

  insert into public.checkins (reservation_id, event_id, scanned_by)
  values (v_res.id, p_event_id, v_uid)
  on conflict (reservation_id) do nothing
  returning scanned_at into v_scanned_at;

  if v_scanned_at is null then
    select c.scanned_at into v_scanned_at from public.checkins c where c.reservation_id = v_res.id;
    return v_ticket || jsonb_build_object('status', 'alreadyCheckedIn', 'scanned_at', v_scanned_at);
  end if;
  return v_ticket || jsonb_build_object('status', 'admitted', 'scanned_at', v_scanned_at);
end;
$$;

-- ======================================================== social proof ===

-- "Soa, Hery R. et 40 autres y vont": the exact head count and the short
-- names of the last 8 people who booked. Uids never leave the database:
-- entries are keyed by a truncated SHA-256 of the uid, which the app
-- compares with the viewer's own key to leave them out.
create function public.event_attendance(p_event_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'count', coalesce((
      select e.capacity - e.available_places from public.events e where e.id = p_event_id
    ), 0),
    'recent', coalesce((
      select jsonb_agg(jsonb_build_object('key', x.key, 'name', x.name) order by x.reserved_at desc)
      from (
        select left(encode(extensions.digest(r.user_id::text, 'sha256'), 'hex'), 16) as key,
               private.short_name(r.user_name) as name,
               r.reserved_at
        from public.reservations r
        where r.event_id = p_event_id
          and r.status = 'confirmed'
          and r.user_id is not null
          and private.short_name(r.user_name) is not null
        order by r.reserved_at desc
        limit 8
      ) x
    ), '[]'::jsonb)
  );
$$;

-- ================================================================ team ===

-- The owner invites an existing organizer account by email (F-16).
create function public.invite_co_organizer(p_event_id uuid, p_email text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid constant uuid := private.require_user();
  v_email text := lower(btrim(coalesce(p_email, '')));
  v_event public.events%rowtype;
  v_invitee public.profiles%rowtype;
  v_seats integer;
begin
  if v_email !~ '^[^@\s]+@[^@\s]+$' then
    perform private.fail_validation(jsonb_build_object('email', 'Adresse email invalide.'));
  end if;
  perform private.throttle('invite:' || v_uid::text, 30, interval '1 minute');

  select * into v_event from public.events e where e.id = p_event_id for update;
  if not found then
    perform private.fail(404, 'notFound', 'Événement introuvable.');
  end if;
  if v_event.organizer_id <> v_uid then
    perform private.fail(403, 'notEventOwner', 'Seul l''organisateur principal compose l''équipe.');
  end if;
  if v_event.starts_at <= now() then
    perform private.fail(409, 'actionRefused', 'Cet événement est passé.');
  end if;

  select * into v_invitee from public.profiles p where p.email = v_email::extensions.citext;
  if not found then
    perform private.fail(404, 'notFound', 'Aucun compte EventHub avec cet email.');
  end if;
  if v_invitee.id = v_uid then
    perform private.fail(409, 'actionRefused', 'Vous êtes déjà l''organisateur de cet événement.');
  end if;
  if v_invitee.role <> 'organizer' then
    perform private.fail(409, 'actionRefused',
      'Ce compte n''est pas organisateur : seul un organisateur peut co-organiser.');
  end if;
  if exists (select 1 from public.event_staff s where s.event_id = p_event_id and s.user_id = v_invitee.id) then
    perform private.fail(409, 'actionRefused', 'Cette personne fait déjà partie de l''équipe.');
  end if;

  select (select count(*) from public.event_staff s where s.event_id = p_event_id)
       + (select count(*) from public.staff_invitations i
          where i.event_id = p_event_id and i.status = 'pending' and i.user_id <> v_invitee.id)
  into v_seats;
  if v_seats >= 10 then
    perform private.fail(409, 'actionRefused', 'Équipe complète : 10 co-organisateurs au plus.');
  end if;

  insert into public.staff_invitations (
    event_id, user_id, email, name, invited_by, invited_by_name, event_title, event_starts_at, status
  )
  values (
    p_event_id, v_invitee.id, v_invitee.email, v_invitee.name, v_uid, v_event.organizer_name,
    v_event.title, v_event.starts_at, 'pending'
  )
  on conflict (event_id, user_id) do update
  set status = 'pending', created_at = now(), responded_at = null,
      invited_by = excluded.invited_by, invited_by_name = excluded.invited_by_name,
      name = excluded.name, email = excluded.email,
      event_title = excluded.event_title, event_starts_at = excluded.event_starts_at;

  perform private.notify(
    v_invitee.id, 'staffInvite', 'Invitation à co-organiser',
    v_event.organizer_name || ' vous propose de co-organiser « ' || v_event.title || ' ».',
    p_event_id);
  perform private.audit('staff.invited', jsonb_build_object('event_id', p_event_id, 'user_id', v_invitee.id));
  return jsonb_build_object('user_id', v_invitee.id, 'name', v_invitee.name);
end;
$$;

create function public.respond_to_staff_invite(p_event_id uuid, p_accept boolean)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid constant uuid := private.require_user();
  v_event public.events%rowtype;
  v_invite public.staff_invitations%rowtype;
begin
  select * into v_event from public.events e where e.id = p_event_id for update;
  select * into v_invite from public.staff_invitations i
  where i.event_id = p_event_id and i.user_id = v_uid
  for update;
  if v_event.id is null or v_invite.event_id is null or v_invite.status <> 'pending' then
    perform private.fail(404, 'notFound', 'Cette invitation n''est plus valable.');
  end if;
  if p_accept and (select count(*) from public.event_staff s where s.event_id = p_event_id) >= 10 then
    perform private.fail(409, 'actionRefused', 'L''équipe est déjà complète.');
  end if;

  update public.staff_invitations
  set status = case when p_accept then 'accepted' else 'declined' end::public.invitation_status,
      responded_at = now()
  where event_id = p_event_id and user_id = v_uid;

  if p_accept then
    insert into public.event_staff (event_id, user_id) values (p_event_id, v_uid)
    on conflict do nothing;
    perform private.notify(
      v_event.organizer_id, 'staffJoined', 'Nouveau co-organisateur',
      coalesce(nullif(v_invite.name, ''), 'Un organisateur') || ' a rejoint l''équipe de « ' || v_event.title || ' ».',
      p_event_id);
  end if;
  perform private.audit(
    case when p_accept then 'staff.accepted' else 'staff.declined' end,
    jsonb_build_object('event_id', p_event_id));
  return jsonb_build_object('accepted', p_accept);
end;
$$;

-- The owner removes a member or cancels an invitation; a member may leave.
create function public.remove_co_organizer(p_event_id uuid, p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid constant uuid := private.require_user();
  v_event public.events%rowtype;
  v_leaving boolean := p_user_id = v_uid;
  v_was_member boolean;
begin
  select * into v_event from public.events e where e.id = p_event_id for update;
  if not found then
    perform private.fail(404, 'notFound', 'Événement introuvable.');
  end if;
  if not v_leaving and v_event.organizer_id <> v_uid then
    perform private.fail(403, 'notEventOwner', 'Seul l''organisateur principal retire un membre de l''équipe.');
  end if;
  if p_user_id = v_event.organizer_id then
    perform private.fail(409, 'actionRefused', 'L''organisateur principal ne quitte pas son propre événement.');
  end if;

  delete from public.event_staff where event_id = p_event_id and user_id = p_user_id;
  v_was_member := found;
  delete from public.staff_invitations where event_id = p_event_id and user_id = p_user_id;

  if v_was_member and not v_leaving then
    perform private.notify(
      p_user_id, 'staffRemoved', 'Retiré de l''équipe',
      'Vous ne co-organisez plus « ' || v_event.title || ' ».', p_event_id);
  end if;
  perform private.audit(
    case when v_leaving then 'staff.left' else 'staff.removed' end,
    jsonb_build_object('event_id', p_event_id, 'user_id', p_user_id));
end;
$$;

-- ========================================================== moderation ===

-- Cancels every seat (paid ones refunded through the job queue), tells each
-- holder and the organizer once, deletes the event and queues its banner.
create function private.remove_event_by_moderation(p_event_id uuid, p_note text)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_event public.events%rowtype;
  v_res public.reservations%rowtype;
  v_count integer := 0;
  v_paid boolean;
begin
  select * into v_event from public.events e where e.id = p_event_id for update;
  if not found then
    perform private.fail(404, 'notFound', 'Événement introuvable.');
  end if;

  -- Seats held on the payment page: released. A payment that still lands
  -- later finds no seat and is refunded by the webhook.
  update public.reservations
  set status = 'cancelled', cancelled_at = now(), cancelled_by = 'moderation',
      payment_status = 'cancelled', hold_expires_at = null, checkout_url = null
  where event_id = p_event_id and status = 'pending';

  for v_res in
    select * from public.reservations r
    where r.event_id = p_event_id and r.status = 'confirmed'
    for update
  loop
    v_paid := v_res.price_paid > 0 and v_res.payment_intent_id is not null;
    if v_paid then
      perform private.enqueue_job('refund', jsonb_build_object(
        'reservation_id', v_res.id, 'payment_intent_id', v_res.payment_intent_id, 'context', 'moderation'));
    end if;
    update public.reservations
    set status = 'cancelled', cancelled_at = now(), cancelled_by = 'moderation'
    where id = v_res.id;
    perform private.notify(
      v_res.user_id, 'eventRemoved', 'Événement annulé',
      '« ' || v_event.title || ' » a été retiré d''EventHub. Votre réservation est annulée'
        || case when v_paid then ' et vous êtes remboursé.' else '.' end,
      p_event_id, v_res.id);
    v_count := v_count + 1;
  end loop;

  perform private.notify(
    v_event.organizer_id, 'eventRemoved', 'Événement retiré par la modération',
    '« ' || v_event.title || ' » : ' || p_note, p_event_id);

  delete from public.events where id = p_event_id;
  perform private.enqueue_storage_delete_url(v_event.image_url);
  return v_count;
end;
$$;

-- An administrator's decision on a queue entry (F-19).
--  review — hide / restore (a human decision is never overridden by the
--           automatic threshold); event — removeEvent; user — suspend /
--           reinstate (Auth ban + sessions revoked + API refused at once);
--  any — dismiss. Every decision is appended to the history and the audit.
create function public.moderate_content(
  p_target_type public.report_target,
  p_target_id text,
  p_action public.moderation_action,
  p_note text default ''
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_admin constant uuid := private.require_user();
  v_note text := btrim(coalesce(p_note, ''));
  v_target uuid := private.try_uuid(p_target_id);
  v_outcome jsonb := '{}'::jsonb;
  v_review public.reviews%rowtype;
  v_status public.moderation_status;
begin
  if not private.is_admin() then
    perform private.fail(403, 'actionRefused', 'Réservé à l''administration.');
  end if;
  if not (
    (p_target_type = 'review' and p_action in ('hide', 'restore', 'dismiss'))
    or (p_target_type = 'event' and p_action in ('removeEvent', 'dismiss'))
    or (p_target_type = 'user' and p_action in ('suspend', 'reinstate', 'dismiss'))
  ) then
    perform private.fail_validation(jsonb_build_object('action', 'Cette décision ne s''applique pas à ce type de contenu.'));
  end if;
  if char_length(v_note) > 500 then
    perform private.fail_validation(jsonb_build_object('note', 'Note : 500 caractères maximum.'));
  end if;
  if p_action in ('removeEvent', 'suspend') and v_note = '' then
    perform private.fail_validation(jsonb_build_object('note', 'Expliquez la décision : la personne concernée la recevra.'));
  end if;

  case p_action
    when 'hide', 'restore' then
      update public.reviews
      set hidden = p_action = 'hide',
          hidden_at = case when p_action = 'hide' then now() end,
          moderated_at = now(),
          moderated_by = v_admin
      where id = v_target
      returning * into v_review;
      if not found then
        perform private.fail(404, 'notFound', 'Avis introuvable.');
      end if;
      if p_action = 'hide' then
        perform private.notify(
          v_review.author_id, 'reviewHidden', 'Votre avis est masqué',
          case when v_note <> '' then 'Motif : ' || v_note
               else 'Plusieurs personnes l''ont signalé. La modération va le vérifier.' end,
          v_review.event_id);
      end if;
    when 'removeEvent' then
      v_outcome := jsonb_build_object(
        'cancelled_reservations', private.remove_event_by_moderation(v_target, v_note));
    when 'suspend', 'reinstate' then
      if v_target = v_admin then
        perform private.fail(409, 'actionRefused', 'Vous ne pouvez pas suspendre votre propre compte.');
      end if;
      update public.profiles
      set suspended_at = case when p_action = 'suspend' then now() end
      where id = v_target;
      if not found then
        perform private.fail(404, 'notFound', 'Compte introuvable.');
      end if;
      update public.organizers set suspended = p_action = 'suspend' where id = v_target;
      update auth.users
      set banned_until = case when p_action = 'suspend' then 'infinity'::timestamptz end
      where id = v_target;
      if p_action = 'suspend' then
        delete from auth.sessions where user_id = v_target;
      end if;
    else
      null;
  end case;

  v_status := case when p_action = 'dismiss' then 'dismissed' else 'resolved' end;
  insert into public.moderation_queue as q (
    target_type, target_id, id, status, decision, decision_note, decided_by, decided_at
  )
  values (p_target_type, p_target_id, '', v_status, p_action, nullif(v_note, ''), v_admin, now())
  on conflict (target_type, target_id) do update
  set status = excluded.status,
      decision = excluded.decision,
      decision_note = excluded.decision_note,
      decided_by = excluded.decided_by,
      decided_at = excluded.decided_at;

  insert into public.moderation_decisions (target_type, target_id, action, note, decided_by)
  values (p_target_type, p_target_id, p_action, v_note, v_admin);

  perform private.audit('moderation.' || p_action::text, jsonb_build_object(
    'target_type', p_target_type, 'target_id', p_target_id, 'note', v_note) || v_outcome);
  return jsonb_build_object('ok', true) || v_outcome;
end;
$$;

-- ====================================================== administrators ===

create function private.apply_admin(p_user uuid, p_admin boolean, p_by uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if p_admin then
    insert into public.administrators (user_id, email, name, granted_by)
    select u.id, u.email, p.name, p_by
    from auth.users u
    left join public.profiles p on p.id = u.id
    where u.id = p_user
    on conflict (user_id) do update
    set email = excluded.email, name = excluded.name,
        granted_by = excluded.granted_by, granted_at = now();
  else
    delete from public.administrators where user_id = p_user;
  end if;

  update auth.users
  set raw_app_meta_data = case
    when p_admin then coalesce(raw_app_meta_data, '{}'::jsonb) || jsonb_build_object('admin', true)
    else coalesce(raw_app_meta_data, '{}'::jsonb) - 'admin'
  end
  where id = p_user;

  perform private.audit(
    case when p_admin then 'admin.granted' else 'admin.revoked' end,
    jsonb_build_object('user_id', p_user, 'by', p_by));
end;
$$;

create function public.set_admin_role(p_email text, p_admin boolean)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_admin constant uuid := private.require_user();
  v_user_id uuid;
  v_email text;
begin
  if not private.is_admin() then
    perform private.fail(403, 'actionRefused', 'Réservé à l''administration.');
  end if;
  select u.id, u.email into v_user_id, v_email
  from auth.users u
  where lower(u.email) = lower(btrim(coalesce(p_email, '')));
  if v_user_id is null then
    perform private.fail(404, 'notFound', 'Aucun compte avec cet email.');
  end if;
  if not p_admin and v_user_id = v_admin then
    perform private.fail(409, 'actionRefused', 'Vous ne pouvez pas retirer votre propre rôle d''administrateur.');
  end if;
  perform private.apply_admin(v_user_id, p_admin, v_admin);
  return jsonb_build_object('user_id', v_user_id, 'email', v_email, 'admin', p_admin);
end;
$$;

-- The first administrator, from a trusted connection (SQL editor or psql —
-- see `make grant-admin`). Executable by no API role.
create function private.grant_admin(p_email text, p_admin boolean default true)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid;
begin
  select u.id into v_user_id from auth.users u where lower(u.email) = lower(btrim(p_email));
  if v_user_id is null then
    raise exception 'Aucun compte avec l''email %', p_email;
  end if;
  perform private.apply_admin(v_user_id, p_admin, null);
  return v_user_id;
end;
$$;

-- ==================================================== account deletion ===

-- Deletes the caller's account and reconciles everything that depends on
-- it, in one transaction. Refused while an upcoming event of theirs has
-- participants. Upcoming seats are given back (paid ones refunded through
-- the queue), history is anonymised for the organizers who rely on it, files
-- are queued for deletion, and the Auth user goes last — its deletion
-- cascades to the profile and every private row.
create function public.delete_my_account()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid constant uuid := private.require_user();
  v_profile public.profiles%rowtype;
  v_blocking integer;
  v_res public.reservations%rowtype;
  v_reservations integer := 0;
begin
  select * into v_profile from public.profiles p where p.id = v_uid;

  if v_profile.role = 'organizer' then
    select count(*) into v_blocking
    from public.events e
    where e.organizer_id = v_uid and e.starts_at > now() and e.capacity > e.available_places;
    if v_blocking > 0 then
      perform private.fail(409, 'actionRefused', format(
        'Suppression impossible : %s événement%s à venir %s des participants. '
          || 'Attendez qu''ils soient passés ou que les places soient libérées.',
        v_blocking,
        case when v_blocking > 1 then 's' else '' end,
        case when v_blocking > 1 then 'ont' else 'a' end));
    end if;
  end if;

  -- Anonymise first, so the cancellation alerts below already carry no name.
  update public.reservations
  set user_name = 'Compte supprimé', user_email = 'supprime@eventhub.invalid'
  where user_id = v_uid;

  for v_res in
    select * from public.reservations r
    where r.user_id = v_uid
      and (r.status = 'pending' or (r.status = 'confirmed' and r.event_starts_at > now()))
    order by r.event_id
  loop
    if v_res.event_id is not null then
      perform 1 from public.events e where e.id = v_res.event_id for update;
    end if;
    if v_res.status = 'confirmed' and v_res.price_paid > 0 and v_res.payment_intent_id is not null then
      perform private.enqueue_job('refund', jsonb_build_object(
        'reservation_id', v_res.id, 'payment_intent_id', v_res.payment_intent_id, 'context', 'account_deleted'));
    end if;
    perform private.move_seat(v_res.event_id, v_res.tier_id, 1);
    update public.reservations
    set status = 'cancelled', cancelled_at = now(), cancelled_by = 'account_deleted',
        payment_status = case when status = 'pending' then 'cancelled' else payment_status end,
        hold_expires_at = null, checkout_url = null
    where id = v_res.id;
    v_reservations := v_reservations + 1;
  end loop;

  update public.reviews set author_name = 'Compte supprimé' where author_id = v_uid;

  if v_profile.role = 'organizer' then
    delete from public.events where organizer_id = v_uid;
    perform private.enqueue_job('storage.delete', jsonb_build_object('bucket', 'event-covers', 'prefix', v_uid::text || '/'));
  end if;
  perform private.enqueue_job('storage.delete', jsonb_build_object('bucket', 'avatars', 'prefix', v_uid::text || '/'));

  perform private.audit('account.deleted', jsonb_build_object(
    'user_id', v_uid, 'role', v_profile.role, 'released_reservations', v_reservations));

  delete from auth.users where id = v_uid;
  return jsonb_build_object('deleted', true);
end;
$$;
