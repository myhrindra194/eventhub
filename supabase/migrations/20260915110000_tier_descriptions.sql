-- =============================================================================
--  EventHub · 11 · Ticket type descriptions
-- =============================================================================
--  A ticket type says what it includes ("Accès backstage, boisson offerte"),
--  up to 160 characters, and its name is capped at 40 — the limits of
--  EventTier in the app, so the form and the database agree. save_event is
--  redefined with the description in its payload: tiers: [{id?, name,
--  description, price, capacity}].
-- =============================================================================

alter table public.event_tiers
  add column description text not null default ''
    constraint event_tiers_description_length check (char_length(description) <= 160);

alter table public.event_tiers drop constraint event_tiers_name_length;
alter table public.event_tiers
  add constraint event_tiers_name_length check (char_length(btrim(name)) between 1 and 40);

create or replace function public.save_event(p_event jsonb)
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
      if char_length(v_name) not between 1 and 40
         or char_length(btrim(coalesce(v_tier ->> 'description', ''))) > 160
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
      v_errors := v_errors || jsonb_build_object('tiers', 'Chaque type a un nom unique (40 caractères au plus), une description courte, au moins une place et un prix valide.');
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
      insert into public.event_tiers (event_id, name, description, price, capacity, available, position)
      values (
        v_event.id,
        btrim(v_tier ->> 'name'),
        btrim(coalesce(v_tier ->> 'description', '')),
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
        set name = v_name, description = btrim(coalesce(v_tier ->> 'description', '')),
            price = v_price, capacity = v_tier_capacity,
            available = v_tier_capacity - (v_current.capacity - v_current.available),
            position = v_position
        where id = v_tier_id;
      else
        insert into public.event_tiers (event_id, name, description, price, capacity, available, position)
        values (v_id, v_name, btrim(coalesce(v_tier ->> 'description', '')), v_price, v_tier_capacity, v_tier_capacity, v_position);
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
