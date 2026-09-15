-- =============================================================================
--  EventHub · 9 · Profile at sign-up, live profile
-- =============================================================================
--
--  With email confirmation on, `auth.signUp` returns no session: the app
--  cannot write the profile itself until the address is confirmed. The name
--  and the role therefore travel as user metadata and the profile is created
--  here, in the transaction that creates the account. The values are
--  re-validated: an invalid role or name simply creates no profile, and the
--  app's "complete your profile" screen takes over — exactly the path of a
--  first Google sign-in, which carries no role.
-- =============================================================================

create function private.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_role text := new.raw_user_meta_data ->> 'role';
  v_name text := btrim(coalesce(new.raw_user_meta_data ->> 'name', ''));
begin
  if new.email is not null
     and v_role in ('participant', 'organizer')
     and char_length(v_name) between 2 and 80 then
    insert into public.profiles (id, name, email, role)
    values (new.id, v_name, new.email, v_role::public.user_role)
    on conflict (id) do nothing;
  end if;
  return null;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function private.handle_new_auth_user();

-- The session stream follows the profile live (name edits, suspension).
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'profiles'
  ) then
    alter publication supabase_realtime add table public.profiles;
  end if;
end;
$$;
