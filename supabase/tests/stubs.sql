-- =============================================================================
--  Stand-ins for what a hosted Supabase database provides, so the migrations
--  run unchanged on PGlite. Only the surface the migrations and the tests
--  touch: roles and their default grants, auth.users / auth.sessions and the
--  JWT helpers, storage path helpers, vault, pg_net, pg_cron, the Realtime
--  publication. Keep in step with what supabase/migrations uses.
-- =============================================================================

create schema extensions;

create role anon nologin;
create role authenticated nologin;
create role service_role nologin bypassrls;
create role authenticator noinherit login;
grant anon, authenticated, service_role to authenticator;

-- Hosted default: new objects in `public` are granted to the API roles; the
-- migrations must revoke what they do not want exposed.
grant usage on schema public to anon, authenticated, service_role;
alter default privileges in schema public grant all on tables to anon, authenticated, service_role;
alter default privileges in schema public grant all on functions to anon, authenticated, service_role;
alter default privileges in schema public grant all on sequences to anon, authenticated, service_role;

create schema auth;
create table auth.users (
  id uuid primary key default gen_random_uuid(),
  email text,
  email_confirmed_at timestamptz,
  raw_app_meta_data jsonb default '{}'::jsonb,
  banned_until timestamptz
);
create table auth.sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users (id) on delete cascade
);
create function auth.uid() returns uuid language sql stable as
  $$ select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $$;
create function auth.jwt() returns jsonb language sql stable as
  $$ select coalesce(nullif(current_setting('request.jwt.claims', true), ''), '{}')::jsonb $$;
grant usage on schema auth to anon, authenticated, service_role;
grant execute on all functions in schema auth to anon, authenticated, service_role;

create schema storage;
grant usage on schema storage to anon, authenticated, service_role;
create table storage.buckets (
  id text primary key, name text, public boolean, file_size_limit bigint, allowed_mime_types text[]
);
create table storage.objects (id uuid primary key default gen_random_uuid(), bucket_id text, name text);
alter table storage.objects enable row level security;
grant all on storage.objects to authenticated;
create function storage.foldername(name text) returns text[] language sql immutable as
  $$ select (string_to_array(name, '/'))[1:array_length(string_to_array(name, '/'), 1) - 1] $$;
create function storage.filename(name text) returns text language sql immutable as
  $$ select (string_to_array(name, '/'))[array_length(string_to_array(name, '/'), 1)] $$;
grant execute on all functions in schema storage to authenticated;

create schema vault;
create table vault.decrypted_secrets (name text, decrypted_secret text);

create schema net;
create table net.calls (url text, headers jsonb, at timestamptz default now());
create function net.http_post(url text, headers jsonb, body jsonb, timeout_milliseconds integer)
returns bigint language sql as
  $$ insert into net.calls (url, headers) values (url, headers); select 1::bigint $$;

create schema cron;
create table cron.job (jobname text primary key, schedule text, command text);
create function cron.schedule(name text, sched text, cmd text) returns bigint language sql as $$
  insert into cron.job values (name, sched, cmd)
  on conflict (jobname) do update set schedule = excluded.schedule, command = excluded.command;
  select 1::bigint
$$;

create publication supabase_realtime;
