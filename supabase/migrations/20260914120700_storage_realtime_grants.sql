-- =============================================================================
--  EventHub · 8/8 · Storage, Realtime, middleware activation, function grants
-- =============================================================================

-- ============================================================= Storage ===

-- Event covers and avatars are promotional/public by nature: public buckets,
-- served by URL. Size and type are enforced by the bucket itself, before
-- any policy runs; SVG is excluded on purpose (executable markup).
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('event-covers', 'event-covers', true, 5 * 1024 * 1024,
   array['image/jpeg', 'image/png', 'image/webp', 'image/heic', 'image/heif']),
  ('avatars', 'avatars', true, 2 * 1024 * 1024,
   array['image/jpeg', 'image/png', 'image/webp', 'image/heic', 'image/heif'])
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

-- Path-based ownership: `<bucket>/<uid>/<file>`. No document read needed.
create function private.storage_path_is_own(p_name text)
returns boolean
language sql
stable
as $$
  select (storage.foldername(p_name))[1] = (select auth.uid()::text)
    and array_length(storage.foldername(p_name), 1) = 1
    and storage.filename(p_name) ~ '^[A-Za-z0-9._-]{1,128}$'
    and storage.filename(p_name) !~ '\.\.';
$$;

create policy "event covers: organizers write their folder"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'event-covers'
    and private.storage_path_is_own(name)
    and private.is_organizer()
  );

create policy "event covers: organizers replace their files"
  on storage.objects for update to authenticated
  using (bucket_id = 'event-covers' and private.storage_path_is_own(name))
  with check (bucket_id = 'event-covers' and private.storage_path_is_own(name));

create policy "event covers: organizers read and delete their files"
  on storage.objects for select to authenticated
  using (bucket_id = 'event-covers' and private.storage_path_is_own(name));

create policy "event covers: organizers delete their files"
  on storage.objects for delete to authenticated
  using (bucket_id = 'event-covers' and private.storage_path_is_own(name));

create policy "avatars: owners write their folder"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'avatars' and private.storage_path_is_own(name));

create policy "avatars: owners replace their files"
  on storage.objects for update to authenticated
  using (bucket_id = 'avatars' and private.storage_path_is_own(name))
  with check (bucket_id = 'avatars' and private.storage_path_is_own(name));

create policy "avatars: owners read their files"
  on storage.objects for select to authenticated
  using (bucket_id = 'avatars' and private.storage_path_is_own(name));

create policy "avatars: owners delete their files"
  on storage.objects for delete to authenticated
  using (bucket_id = 'avatars' and private.storage_path_is_own(name));

-- ============================================================ Realtime ===

-- Live screens (catalogue, seat gauge, tickets, guest list, door counter,
-- notification bell, team, moderation queue). Realtime applies RLS to what
-- each subscriber receives.
do $$
declare
  v_table text;
begin
  foreach v_table in array array[
    'events', 'event_tiers', 'event_staff', 'staff_invitations', 'reservations',
    'checkins', 'waitlist_entries', 'favorites', 'follows', 'reviews',
    'notifications', 'organizers', 'moderation_queue'
  ] loop
    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = v_table
    ) then
      execute format('alter publication supabase_realtime add table public.%I', v_table);
    end if;
  end loop;
end;
$$;

-- Deletions must carry the whole old row for the client to know which list
-- entry disappeared.
alter table public.favorites replica identity full;
alter table public.follows replica identity full;
alter table public.notifications replica identity full;
alter table public.waitlist_entries replica identity full;
alter table public.event_staff replica identity full;
alter table public.staff_invitations replica identity full;
alter table public.event_tiers replica identity full;

-- ================================================= request middleware ===

alter role authenticator set pgrst.db_pre_request to 'public.api_pre_request';
notify pgrst, 'reload config';

-- ===================================================== function grants ===

-- Start from nothing, then grant exactly what each role calls.
revoke execute on all functions in schema public from public, anon, authenticated;
revoke execute on all functions in schema private from public, anon, authenticated;

-- Helpers evaluated with the caller's rights: RLS and Storage policies, and
-- the few non-definer triggers that raise business errors.
grant execute on function
  private.is_admin(),
  private.my_role(),
  private.is_organizer(),
  private.is_verified(),
  private.is_event_team(uuid),
  private.can_review(uuid),
  private.storage_path_is_own(text),
  private.fail(integer, text, text),
  private.fail_validation(jsonb),
  private.try_uuid(text),
  private.require_user()
to authenticated;

grant execute on function public.api_pre_request() to anon, authenticated;

-- The application API.
grant execute on function
  public.register_device(text, text, public.device_platform, text),
  public.save_event(jsonb),
  public.delete_event(uuid),
  public.reserve_seat(uuid, uuid),
  public.cancel_reservation(uuid),
  public.join_waitlist(uuid),
  public.leave_waitlist(uuid),
  public.check_in_ticket(uuid, uuid),
  public.event_attendance(uuid),
  public.invite_co_organizer(uuid, text),
  public.respond_to_staff_invite(uuid, boolean),
  public.remove_co_organizer(uuid, uuid),
  public.moderate_content(public.report_target, text, public.moderation_action, text),
  public.set_admin_role(text, boolean),
  public.delete_my_account()
to authenticated;

-- Server-side only: Edge Functions with the service role key.
grant execute on function
  public.payments_hold_seat(uuid, uuid, uuid, integer),
  public.payments_attach_session(uuid, text, text),
  public.payments_release_hold(uuid, public.payment_status),
  public.payments_release_own_hold(uuid, uuid),
  public.payments_fulfill(uuid, text, integer, text, text),
  public.payments_mark_refunded(uuid, text, text),
  public.payments_begin_refund(uuid, uuid),
  public.payments_complete_refund(uuid, text),
  public.payments_refund_settled(uuid, text),
  public.jobs_claim(integer),
  public.jobs_complete(bigint),
  public.jobs_fail(bigint, text),
  public.push_payload(uuid),
  public.devices_forget_tokens(text[]),
  public.public_event_snapshot(uuid)
to service_role;
