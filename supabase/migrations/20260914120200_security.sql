-- =============================================================================
--  EventHub · 3/8 · Security
--  Identity helpers, column-level grants, Row Level Security, and the
--  request middleware PostgREST runs before every API call.
-- =============================================================================
--
--  Threat model: the client is hostile. Anyone with an account can call the
--  REST API directly with a crafted payload. Three layers therefore stack:
--    1. grants — which columns a role may insert or update at all;
--    2. RLS — which rows it may see and touch;
--    3. RPCs and triggers — every business invariant, in a transaction.
--  `anon` has no access to any table: every feature requires an account.
-- =============================================================================

-- ============================================================= identity ===

create function private.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (select 1 from public.administrators a where a.user_id = auth.uid());
$$;

create function private.my_role()
returns public.user_role
language sql
stable
security definer
set search_path = ''
as $$
  select p.role from public.profiles p where p.id = auth.uid();
$$;

create function private.is_organizer()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.profiles p where p.id = auth.uid() and p.role = 'organizer'
  );
$$;

-- A verified email is required for content other people see.
create function private.is_verified()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from auth.users u where u.id = auth.uid() and u.email_confirmed_at is not null
  );
$$;

-- The organizer of an event or one of its co-organizers (F-16).
create function private.is_event_team(p_event_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select p_event_id is not null and (
    exists (select 1 from public.events e where e.id = p_event_id and e.organizer_id = auth.uid())
    or exists (select 1 from public.event_staff s where s.event_id = p_event_id and s.user_id = auth.uid())
  );
$$;

-- Attendance is the right to review: a confirmed seat on an event that has
-- started, from a participant with a verified email.
create function private.can_review(p_event_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select private.my_role() = 'participant'
    and private.is_verified()
    and exists (
      select 1 from public.reservations r
      where r.event_id = p_event_id
        and r.user_id = auth.uid()
        and r.status = 'confirmed'
        and r.event_starts_at < now()
    );
$$;

grant execute on function
  private.is_admin(),
  private.my_role(),
  private.is_organizer(),
  private.is_verified(),
  private.is_event_team(uuid),
  private.can_review(uuid)
to authenticated;

-- =============================================================== grants ===

revoke all on all tables in schema public from anon, authenticated;
revoke all on all sequences in schema public from anon, authenticated;
alter default privileges in schema public revoke all on tables from anon, authenticated;

-- profiles: role, email and timestamps are never client-writable.
grant select on public.profiles to authenticated;
grant insert (id, name, email, role, bio, photo_url) on public.profiles to authenticated;
grant update (name, bio, photo_url) on public.profiles to authenticated;

grant select on public.notification_preferences to authenticated;
grant update (event_reminders, booking_alerts, followed_organizers)
  on public.notification_preferences to authenticated;

-- devices: written through public.register_device.
grant select, delete on public.devices to authenticated;

grant select on public.administrators to authenticated;
grant select on public.organizers to authenticated;
grant select, delete on public.follows to authenticated;
grant insert (organizer_id) on public.follows to authenticated;

-- Events, types, teams, reservations, check-ins and waiting lists are
-- written only through RPCs: reading is all a client does directly.
grant select on
  public.events,
  public.event_tiers,
  public.event_staff,
  public.staff_invitations,
  public.reservations,
  public.checkins,
  public.waitlist_entries
to authenticated;

grant select, delete on public.favorites to authenticated;
grant insert (event_id) on public.favorites to authenticated;

grant select, delete on public.reviews to authenticated;
grant insert (event_id, rating, comment) on public.reviews to authenticated;
grant update (rating, comment) on public.reviews to authenticated;

grant select on public.reports to authenticated;
grant insert (target_type, target_id, reason, details) on public.reports to authenticated;

grant select on public.moderation_queue, public.moderation_decisions to authenticated;

grant select, delete on public.notifications to authenticated;
grant update (read_at) on public.notifications to authenticated;

-- ================================================================== RLS ===

alter table public.profiles enable row level security;
alter table public.notification_preferences enable row level security;
alter table public.devices enable row level security;
alter table public.administrators enable row level security;
alter table public.organizers enable row level security;
alter table public.follows enable row level security;
alter table public.events enable row level security;
alter table public.event_tiers enable row level security;
alter table public.event_staff enable row level security;
alter table public.staff_invitations enable row level security;
alter table public.reservations enable row level security;
alter table public.checkins enable row level security;
alter table public.waitlist_entries enable row level security;
alter table public.favorites enable row level security;
alter table public.reviews enable row level security;
alter table public.reports enable row level security;
alter table public.moderation_queue enable row level security;
alter table public.moderation_decisions enable row level security;
alter table public.notifications enable row level security;

-- `(select auth.uid())` is evaluated once per statement (init plan), not
-- once per row.

-- ---- profiles: private to their owner (and to moderation) --------------
create policy profiles_select on public.profiles
  for select to authenticated
  using (id = (select auth.uid()) or (select private.is_admin()));

-- The email is overwritten from auth.users by a trigger; the role is chosen
-- once, here, and frozen.
create policy profiles_insert on public.profiles
  for insert to authenticated
  with check (id = (select auth.uid()));

create policy profiles_update on public.profiles
  for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

-- ---- preferences and devices: owner only --------------------------------
create policy notification_preferences_select on public.notification_preferences
  for select to authenticated
  using (user_id = (select auth.uid()));

create policy notification_preferences_update on public.notification_preferences
  for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

create policy devices_select on public.devices
  for select to authenticated
  using (user_id = (select auth.uid()));

create policy devices_delete on public.devices
  for delete to authenticated
  using (user_id = (select auth.uid()));

-- ---- administrators: visible to administrators --------------------------
create policy administrators_select on public.administrators
  for select to authenticated
  using ((select private.is_admin()));

-- ---- organizers: public, read-only --------------------------------------
create policy organizers_select on public.organizers
  for select to authenticated
  using (true);

-- ---- follows: private to the follower -----------------------------------
-- Who follows an organizer is public to nobody, the organizer included.
create policy follows_select on public.follows
  for select to authenticated
  using (follower_id = (select auth.uid()));

create policy follows_insert on public.follows
  for insert to authenticated
  with check (follower_id = (select auth.uid()));

create policy follows_delete on public.follows
  for delete to authenticated
  using (follower_id = (select auth.uid()));

-- ---- the catalogue: every signed-in user --------------------------------
create policy events_select on public.events
  for select to authenticated
  using (true);

create policy event_tiers_select on public.event_tiers
  for select to authenticated
  using (true);

create policy event_staff_select on public.event_staff
  for select to authenticated
  using (true);

create policy staff_invitations_select on public.staff_invitations
  for select to authenticated
  using (user_id = (select auth.uid()) or private.is_event_team(event_id));

-- ---- reservations: the participant, the event team, moderation ---------
-- A guest list never leaks to an organizer outside the team.
create policy reservations_select on public.reservations
  for select to authenticated
  using (
    user_id = (select auth.uid())
    or private.is_event_team(event_id)
    or (select private.is_admin())
  );

create policy checkins_select on public.checkins
  for select to authenticated
  using (private.is_event_team(event_id));

create policy waitlist_select on public.waitlist_entries
  for select to authenticated
  using (user_id = (select auth.uid()) or private.is_event_team(event_id));

-- ---- favorites: owner only ----------------------------------------------
create policy favorites_select on public.favorites
  for select to authenticated
  using (user_id = (select auth.uid()));

create policy favorites_insert on public.favorites
  for insert to authenticated
  with check (user_id = (select auth.uid()));

create policy favorites_delete on public.favorites
  for delete to authenticated
  using (user_id = (select auth.uid()));

-- ---- reviews -------------------------------------------------------------
-- A hidden review is seen only by its author and by moderation.
create policy reviews_select on public.reviews
  for select to authenticated
  using (
    not hidden
    or author_id = (select auth.uid())
    or (select private.is_admin())
  );

-- WITH CHECK runs after the BEFORE INSERT trigger has stamped author_id.
create policy reviews_insert on public.reviews
  for insert to authenticated
  with check (author_id = (select auth.uid()) and private.can_review(event_id));

create policy reviews_update on public.reviews
  for update to authenticated
  using (author_id = (select auth.uid()))
  with check (author_id = (select auth.uid()));

create policy reviews_delete on public.reviews
  for delete to authenticated
  using (author_id = (select auth.uid()) or (select private.is_admin()));

-- ---- reports: write-only for reporters ----------------------------------
create policy reports_insert on public.reports
  for insert to authenticated
  with check (reporter_id = (select auth.uid()));

create policy reports_select on public.reports
  for select to authenticated
  using ((select private.is_admin()));

create policy moderation_queue_select on public.moderation_queue
  for select to authenticated
  using ((select private.is_admin()));

create policy moderation_decisions_select on public.moderation_decisions
  for select to authenticated
  using ((select private.is_admin()));

-- ---- notifications: owner only, created by the server -------------------
create policy notifications_select on public.notifications
  for select to authenticated
  using (user_id = (select auth.uid()));

create policy notifications_update on public.notifications
  for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

create policy notifications_delete on public.notifications
  for delete to authenticated
  using (user_id = (select auth.uid()));

-- =================================================== request middleware ===

-- Runs before every PostgREST request (see `pgrst.db_pre_request`, set in
-- 8/8). Two jobs:
--   * a suspended account is refused at once — an access token stays valid
--     up to an hour, the suspension does not wait for it;
--   * writes are rate-limited per account (240 per minute), which stops a
--     runaway client loop or a scripted abuse before it reaches the tables.
create function public.api_pre_request()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_method text := current_setting('request.method', true);
begin
  if v_uid is null then
    return;
  end if;

  if exists (
    select 1 from public.profiles p where p.id = v_uid and p.suspended_at is not null
  ) then
    perform private.fail(403, 'accountSuspended', 'Ce compte est suspendu par la modération.');
  end if;

  if v_method in ('POST', 'PATCH', 'PUT', 'DELETE') then
    perform private.throttle('api:' || v_uid::text, 240, interval '1 minute');
  end if;
end;
$$;

grant execute on function public.api_pre_request() to anon, authenticated;
