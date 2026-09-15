-- =============================================================================
--  EventHub · 10 · Live notification preferences
-- =============================================================================
--  The settings screen follows the preferences live (a change made on another
--  device shows up at once). Realtime applies the owner-only RLS policy.

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public'
      and tablename = 'notification_preferences'
  ) then
    alter publication supabase_realtime add table public.notification_preferences;
  end if;
end;
$$;
