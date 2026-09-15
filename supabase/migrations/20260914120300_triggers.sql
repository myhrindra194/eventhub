-- =============================================================================
--  EventHub · 4/8 · Triggers
--  Integrity rules that must hold whoever writes, and derived data kept in
--  step inside the same transaction: counters, the public organizer page,
--  ticket-type totals, notifications.
-- =============================================================================
--
--  Trigger functions that touch another table are SECURITY DEFINER: they run
--  on behalf of a client write (a follow, a review, a report) whose role has
--  no right on the table being maintained. Unlike Cloud Functions triggers,
--  these run exactly once and atomically with the write — no idempotency
--  marker is needed, and a failure rolls the whole write back.
-- =============================================================================

-- ============================================================ notify() ===

-- Writes an in-app notification, honouring the recipient's preference.
-- Push delivery follows asynchronously (notifications_enqueue_push).
create function private.notify(
  p_user uuid,
  p_type public.notification_type,
  p_title text,
  p_body text,
  p_event uuid default null,
  p_reservation uuid default null,
  p_preference text default null
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
begin
  if p_user is null or not exists (select 1 from public.profiles p where p.id = p_user) then
    return false;
  end if;

  if p_preference is not null and exists (
    select 1
    from public.notification_preferences np
    where np.user_id = p_user
      and case p_preference
            when 'event_reminders' then not np.event_reminders
            when 'booking_alerts' then not np.booking_alerts
            when 'followed_organizers' then not np.followed_organizers
            else false
          end
  ) then
    return false;
  end if;

  insert into public.notifications (user_id, type, title, body, event_id, reservation_id)
  values (p_user, p_type, p_title, p_body, p_event, p_reservation);
  return true;
end;
$$;

create function private.enqueue_job(p_kind text, p_payload jsonb, p_delay interval default interval '0')
returns void
language sql
security definer
set search_path = ''
as $$
  insert into private.jobs (kind, payload, run_after) values (p_kind, p_payload, now() + p_delay);
$$;

-- A public Storage URL of this project → a deletion job for the object.
create function private.enqueue_storage_delete_url(p_url text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_match text[];
begin
  v_match := regexp_match(coalesce(p_url, ''), '/storage/v1/object/public/(event-covers|avatars)/([^?#]+)');
  if v_match is not null then
    perform private.enqueue_job('storage.delete', jsonb_build_object('bucket', v_match[1], 'paths', jsonb_build_array(v_match[2])));
  end if;
end;
$$;

-- ======================================================== updated_at ===

create trigger profiles_touch before update on public.profiles
  for each row execute function private.touch_updated_at();
create trigger notification_preferences_touch before update on public.notification_preferences
  for each row execute function private.touch_updated_at();
create trigger organizers_touch before update on public.organizers
  for each row execute function private.touch_updated_at();
create trigger events_touch before update on public.events
  for each row execute function private.touch_updated_at();
create trigger event_tiers_touch before update on public.event_tiers
  for each row execute function private.touch_updated_at();
create trigger reservations_touch before update on public.reservations
  for each row execute function private.touch_updated_at();
create trigger moderation_queue_touch before update on public.moderation_queue
  for each row execute function private.touch_updated_at();

-- ========================================================== profiles ===

create function private.profiles_before_insert()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_email text;
begin
  -- The email is the authenticated one, never what the client sent.
  select u.email into v_email from auth.users u where u.id = new.id;
  if v_email is null then
    perform private.fail(422, 'validation', 'Compte d''authentification introuvable.');
  end if;
  new.email := v_email;
  new.name := btrim(new.name);
  new.bio := nullif(btrim(coalesce(new.bio, '')), '');
  new.suspended_at := null;
  new.created_at := now();
  new.updated_at := now();
  return new;
end;
$$;

create trigger profiles_before_insert before insert on public.profiles
  for each row execute function private.profiles_before_insert();

-- The whole authorisation model rests on the role never changing.
create function private.profiles_before_update()
returns trigger
language plpgsql
as $$
begin
  if new.role is distinct from old.role then
    perform private.fail(403, 'actionRefused', 'Le rôle d''un compte ne change pas.');
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

create trigger profiles_before_update before update on public.profiles
  for each row execute function private.profiles_before_update();

create function private.profiles_after_insert()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.notification_preferences (user_id) values (new.id)
  on conflict (user_id) do nothing;

  if new.role = 'organizer' then
    insert into public.organizers (id, name, bio, photo_url, member_since)
    values (new.id, new.name, coalesce(new.bio, ''), new.photo_url, new.created_at)
    on conflict (id) do nothing;
  end if;

  -- Mirrored into the JWT's app_metadata (not user-editable) so the app
  -- knows the role at sign-in without a query.
  update auth.users
  set raw_app_meta_data = coalesce(raw_app_meta_data, '{}'::jsonb) || jsonb_build_object('role', new.role)
  where id = new.id;
  return null;
end;
$$;

create trigger profiles_after_insert after insert on public.profiles
  for each row execute function private.profiles_after_insert();

create function private.profiles_after_update()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.role = 'organizer'
     and (new.name, new.bio, new.photo_url) is distinct from (old.name, old.bio, old.photo_url) then
    update public.organizers
    set name = new.name, bio = coalesce(new.bio, ''), photo_url = new.photo_url
    where id = new.id;
  end if;

  if new.name is distinct from old.name then
    if new.role = 'organizer' then
      update public.events set organizer_name = new.name where organizer_id = new.id;
    end if;
    update public.waitlist_entries set user_name = new.name where user_id = new.id;
  end if;
  return null;
end;
$$;

create trigger profiles_after_update after update on public.profiles
  for each row execute function private.profiles_after_update();

-- An email changed in Supabase Auth (confirmed change) reaches the profile.
create function private.sync_profile_email()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform set_config('eventhub.email_sync', 'on', true);
  update public.profiles set email = new.email where id = new.id;
  perform set_config('eventhub.email_sync', 'off', true);
  return null;
end;
$$;

create trigger on_auth_user_email_changed
  after update of email on auth.users
  for each row
  when (old.email is distinct from new.email and new.email is not null)
  execute function private.sync_profile_email();

-- ============================================================ follows ===

create function private.follows_counter()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    update public.organizers set follower_count = follower_count + 1 where id = new.organizer_id;
  else
    update public.organizers set follower_count = greatest(follower_count - 1, 0) where id = old.organizer_id;
  end if;
  return null;
end;
$$;

create trigger follows_counter after insert or delete on public.follows
  for each row execute function private.follows_counter();

-- ============================================================= events ===

-- New upcoming event → every follower who did not opt out, in one statement.
create function private.announce_event(p_event_id uuid)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_count integer;
begin
  insert into public.notifications (user_id, type, title, body, event_id)
  select f.follower_id,
         'newEvent',
         e.organizer_name || ' publie un événement',
         '« ' || e.title || ' » · ' || private.fr_datetime(e.starts_at) || ' · ' || e.location || '.',
         e.id
  from public.events e
  join public.follows f on f.organizer_id = e.organizer_id
  left join public.notification_preferences np on np.user_id = f.follower_id
  where e.id = p_event_id
    and coalesce(np.followed_organizers, true);
  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

create function private.events_after_insert()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.organizers set event_count = event_count + 1 where id = new.organizer_id;
  if new.starts_at > now() then
    perform private.announce_event(new.id);
  end if;
  return null;
end;
$$;

create trigger events_after_insert after insert on public.events
  for each row execute function private.events_after_insert();

create function private.events_after_delete()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.organizers set event_count = greatest(event_count - 1, 0) where id = old.organizer_id;
  return null;
end;
$$;

create trigger events_after_delete after delete on public.events
  for each row execute function private.events_after_delete();

-- Keeps ticket snapshots true when an organizer moves the date or the place,
-- and tells the waiting list when seats open up.
create function private.events_after_update()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_freed integer := new.available_places - old.available_places;
  v_user uuid;
begin
  if (new.title, new.starts_at, new.location) is distinct from (old.title, old.starts_at, old.location) then
    update public.reservations
    set event_title = new.title, event_starts_at = new.starts_at, event_location = new.location,
        reminder_sent_at = case when new.starts_at is distinct from old.starts_at then null else reminder_sent_at end
    where event_id = new.id and status in ('confirmed', 'pending');
  end if;

  -- As many people as seats freed, oldest first, each notified once. No seat
  -- is held for them: first come, first served, as the message says.
  if v_freed > 0 and new.starts_at > now() then
    for v_user in
      with next_up as (
        select w.event_id, w.user_id
        from public.waitlist_entries w
        where w.event_id = new.id and w.notified_at is null
        order by w.created_at
        limit v_freed
        for update skip locked
      )
      update public.waitlist_entries w
      set notified_at = now()
      from next_up
      where w.event_id = next_up.event_id and w.user_id = next_up.user_id
      returning w.user_id
    loop
      perform private.notify(
        v_user,
        'waitlist',
        'Une place s''est libérée',
        '« ' || new.title || ' » : ' || v_freed || ' place' || case when v_freed > 1 then 's' else '' end
          || ' disponible' || case when v_freed > 1 then 's' else '' end
          || '. Premier arrivé, premier servi.',
        new.id,
        null,
        'event_reminders'
      );
    end loop;
  end if;
  return null;
end;
$$;

create trigger events_after_update after update on public.events
  for each row execute function private.events_after_update();

-- ======================================================= ticket types ===

create function private.event_tiers_before_write()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' and (
    select count(*) from public.event_tiers t where t.event_id = new.event_id
  ) >= 6 then
    perform private.fail(422, 'validation', '6 types de billets au plus.');
  end if;
  if tg_op = 'UPDATE' and new.event_id is distinct from old.event_id then
    perform private.fail(403, 'actionRefused', 'Un type de billet ne change pas d''événement.');
  end if;
  new.name := btrim(new.name);
  return new;
end;
$$;

create trigger event_tiers_before_write before insert or update on public.event_tiers
  for each row execute function private.event_tiers_before_write();

-- With types, the event's capacity and remaining seats are exactly their
-- sums. Every seat movement goes through the type; this keeps the event
-- in step inside the same statement.
create function private.event_tiers_sync_totals()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_event_id uuid := case when tg_op = 'DELETE' then old.event_id else new.event_id end;
begin
  update public.events e
  set capacity = t.capacity, available_places = t.available
  from (
    select sum(capacity)::integer as capacity, sum(available)::integer as available, count(*) as n
    from public.event_tiers
    where event_id = v_event_id
  ) t
  where e.id = v_event_id
    and t.n > 0
    and (e.capacity, e.available_places) is distinct from (t.capacity, t.available);
  return null;
end;
$$;

create trigger event_tiers_sync_totals after insert or update or delete on public.event_tiers
  for each row execute function private.event_tiers_sync_totals();

-- ======================================================= reservations ===

-- Bookings and cancellations → the organizer and every co-organizer, each
-- with their own preference. A booking also ends that person's wait.
create function private.reservations_after_write()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_booked boolean;
  v_cancelled boolean;
  v_member uuid;
begin
  v_booked := new.status = 'confirmed'
    and (tg_op = 'INSERT' or old.status is distinct from 'confirmed');
  v_cancelled := tg_op = 'UPDATE'
    and old.status = 'confirmed'
    and new.status = 'cancelled'
    -- A moderation removal tells the organizer once, not once per guest.
    and new.cancelled_by is distinct from 'moderation';

  if new.event_id is null or not (v_booked or v_cancelled) then
    return null;
  end if;

  if v_booked then
    delete from public.waitlist_entries where event_id = new.event_id and user_id = new.user_id;
  end if;

  for v_member in
    select e.organizer_id from public.events e where e.id = new.event_id
    union
    select s.user_id from public.event_staff s where s.event_id = new.event_id
  loop
    perform private.notify(
      v_member,
      case when v_booked then 'booking' else 'cancellation' end::public.notification_type,
      case when v_booked then 'Nouvelle réservation' else 'Réservation annulée' end,
      case when v_booked
        then new.user_name || ' a réservé une place pour « ' || new.event_title || ' ».'
        else new.user_name || ' a libéré sa place pour « ' || new.event_title || ' ».'
      end,
      new.event_id,
      new.id,
      'booking_alerts'
    );
  end loop;
  return null;
end;
$$;

create trigger reservations_after_write after insert or update of status on public.reservations
  for each row execute function private.reservations_after_write();

-- ============================================================ reviews ===

create function private.reviews_before_insert()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  new.author_id := coalesce(auth.uid(), new.author_id);
  select p.name into new.author_name from public.profiles p where p.id = new.author_id;
  select e.organizer_id into new.organizer_id from public.events e where e.id = new.event_id;
  if new.author_name is null then
    perform private.fail(403, 'notAttendee', 'Seuls les participants inscrits peuvent laisser un avis.');
  end if;
  new.comment := btrim(coalesce(new.comment, ''));
  new.hidden := false;
  new.hidden_at := null;
  new.moderated_at := null;
  new.moderated_by := null;
  new.created_at := now();
  new.updated_at := null;
  return new;
end;
$$;

create trigger reviews_before_insert before insert on public.reviews
  for each row execute function private.reviews_before_insert();

create function private.reviews_before_update()
returns trigger
language plpgsql
as $$
begin
  if auth.uid() is not null and auth.uid() = old.author_id
     and (new.rating, new.comment) is distinct from (old.rating, old.comment) then
    if old.updated_at is not null and old.updated_at > now() - interval '1 second' then
      perform private.fail(429, 'tooManyRequests', 'Patientez un instant avant de modifier à nouveau.');
    end if;
    new.updated_at := now();
  end if;
  new.comment := btrim(coalesce(new.comment, ''));
  return new;
end;
$$;

create trigger reviews_before_update before update on public.reviews
  for each row execute function private.reviews_before_update();

-- The organizer's rating counts visible reviews only: hiding removes a
-- review from it, restoring adds it back.
create function private.reviews_rating()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_before integer;
  v_after integer;
  v_organizer uuid;
begin
  if tg_op in ('UPDATE', 'DELETE') and not old.hidden then
    v_before := old.rating;
  end if;
  if tg_op in ('INSERT', 'UPDATE') and not new.hidden then
    v_after := new.rating;
  end if;
  if v_before is not distinct from v_after then
    return null;
  end if;
  v_organizer := case when tg_op = 'DELETE' then old.organizer_id else new.organizer_id end;

  update public.organizers
  set rating_sum = greatest(rating_sum + coalesce(v_after, 0) - coalesce(v_before, 0), 0),
      rating_count = greatest(
        rating_count + (v_after is not null)::integer - (v_before is not null)::integer, 0)
  where id = v_organizer;
  return null;
end;
$$;

create trigger reviews_rating after insert or update or delete on public.reviews
  for each row execute function private.reviews_rating();

-- ========================================================= moderation ===

create function private.moderation_queue_before_insert()
returns trigger
language plpgsql
as $$
begin
  new.id := new.target_type::text || '_' || new.target_id;
  return new;
end;
$$;

create trigger moderation_queue_before_insert before insert on public.moderation_queue
  for each row execute function private.moderation_queue_before_insert();

create function private.reports_before_insert()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  new.reporter_id := coalesce(auth.uid(), new.reporter_id);
  new.details := btrim(coalesce(new.details, ''));
  new.created_at := now();

  if new.reason = 'other' and new.details = '' then
    perform private.fail_validation(jsonb_build_object('details', 'Précisez ce qui ne va pas.'));
  end if;

  case new.target_type
    when 'user' then
      if new.target_id = new.reporter_id::text then
        perform private.fail(409, 'cannotReportSelf', 'Vous ne pouvez pas vous signaler vous-même.');
      end if;
      if not exists (select 1 from public.profiles p where p.id = private.try_uuid(new.target_id)) then
        perform private.fail(404, 'notFound', 'Ce compte n''existe plus.');
      end if;
    when 'review' then
      if exists (
        select 1 from public.reviews r
        where r.id = private.try_uuid(new.target_id) and r.author_id = new.reporter_id
      ) then
        perform private.fail(409, 'cannotReportSelf', 'Vous ne pouvez pas signaler votre propre avis.');
      end if;
      if not exists (select 1 from public.reviews r where r.id = private.try_uuid(new.target_id)) then
        perform private.fail(404, 'notFound', 'Cet avis n''existe plus.');
      end if;
    when 'event' then
      if exists (
        select 1 from public.events e
        where e.id = private.try_uuid(new.target_id) and e.organizer_id = new.reporter_id
      ) then
        perform private.fail(409, 'cannotReportSelf', 'Vous ne pouvez pas signaler votre propre événement.');
      end if;
      if not exists (select 1 from public.events e where e.id = private.try_uuid(new.target_id)) then
        perform private.fail(404, 'notFound', 'Cet événement n''existe plus.');
      end if;
  end case;
  return new;
end;
$$;

create trigger reports_before_insert before insert on public.reports
  for each row execute function private.reports_before_insert();

-- Each report feeds the queue entry of its target. A review reported by 3
-- distinct people is hidden at once (cheap to hide, cheap to restore); an
-- event or an account never is — people hold tickets, a human decides. A
-- moderator's decision (moderated_at) is never overridden by the threshold.
create function private.reports_after_insert()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_count integer;
  v_hidden boolean := false;
  v_review public.reviews%rowtype;
begin
  select count(*) into v_count
  from public.reports
  where target_type = new.target_type and target_id = new.target_id;

  if new.target_type = 'review' and v_count >= 3 then
    update public.reviews
    set hidden = true, hidden_at = now()
    where id = private.try_uuid(new.target_id) and not hidden and moderated_at is null
    returning * into v_review;
    v_hidden := found;
    if v_hidden then
      perform private.notify(
        v_review.author_id, 'reviewHidden', 'Votre avis est masqué',
        'Plusieurs personnes l''ont signalé. La modération va le vérifier.',
        v_review.event_id);
    end if;
  end if;

  insert into public.moderation_queue as q (target_type, target_id, id, report_count, last_reason, status, auto_hidden)
  values (new.target_type, new.target_id, '', v_count, new.reason, 'open', v_hidden)
  on conflict (target_type, target_id) do update
  set report_count = excluded.report_count,
      last_reason = excluded.last_reason,
      status = 'open',
      auto_hidden = q.auto_hidden or excluded.auto_hidden;

  perform private.audit('report.received', jsonb_build_object(
    'target_type', new.target_type, 'target_id', new.target_id, 'reason', new.reason,
    'report_count', v_count, 'auto_hidden', v_hidden));
  return null;
end;
$$;

create trigger reports_after_insert after insert on public.reports
  for each row execute function private.reports_after_insert();

-- ====================================================== notifications ===

-- Readers may only stamp read_at, and only forwards.
create function private.notifications_before_update()
returns trigger
language plpgsql
as $$
begin
  if old.read_at is not null then
    new.read_at := old.read_at;
  elsif new.read_at is not null then
    new.read_at := now();
  end if;
  return new;
end;
$$;

create trigger notifications_before_update before update on public.notifications
  for each row execute function private.notifications_before_update();

-- One push job per notification whose recipient has a device, enqueued in
-- the transaction that created it; the worker is woken after commit.
create function private.notifications_enqueue_push()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_count integer;
begin
  insert into private.jobs (kind, payload)
  select 'push', jsonb_build_object('notification_id', i.id)
  from inserted i
  where exists (select 1 from public.devices d where d.user_id = i.user_id);
  get diagnostics v_count = row_count;
  if v_count > 0 then
    perform private.kick_worker();
  end if;
  return null;
end;
$$;

-- Defined here as a no-op so the trigger can be created; 7/8 replaces it
-- with the pg_net call once the job plumbing exists.
create function private.kick_worker()
returns void
language plpgsql
as $$
begin
  return;
end;
$$;

create trigger notifications_enqueue_push
  after insert on public.notifications
  referencing new table as inserted
  for each statement execute function private.notifications_enqueue_push();
