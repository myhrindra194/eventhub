-- =============================================================================
--  EventHub · 1/8 · Foundation
--  Extensions, the private schema, enums, and the plumbing every later
--  migration relies on: typed errors, audit trail, rate limiting, formatting.
-- =============================================================================
--
--  Conventions used across all migrations
--  --------------------------------------
--  * `public` holds what PostgREST exposes: tables (behind RLS) and the RPCs
--    the app may call. Nothing in `public` is executable by `anon`.
--  * `private` is never exposed over HTTP. It holds helpers, trigger
--    functions, the job queue and the audit trail.
--  * Every SECURITY DEFINER function pins `search_path = ''` and schema-
--    qualifies every object, so a caller cannot shadow a table or operator.
--  * Business errors are raised with SQLSTATE `PTnnn`, which PostgREST turns
--    into HTTP status `nnn`; the `hint` carries the rule key the Flutter app
--    maps to `BusinessRule` (see lib/core/errors/error_mapper.dart), the
--    `message` is French and safe to show, the `detail` carries field errors.
-- =============================================================================

create extension if not exists pgcrypto with schema extensions;
create extension if not exists citext with schema extensions;
create extension if not exists pg_net with schema extensions;
create extension if not exists pg_cron with schema pg_catalog;

create schema if not exists private;
revoke all on schema private from public;
grant usage on schema private to authenticated, service_role;

-- Functions are not executable by everyone unless granted explicitly.
alter default privileges in schema public revoke execute on functions from public;
alter default privileges in schema private revoke execute on functions from public;
alter default privileges for role postgres in schema public
  revoke execute on functions from anon, authenticated;

-- ---------------------------------------------------------------- enums ---

create type public.user_role as enum ('participant', 'organizer');

create type public.event_category as enum (
  'conference', 'meetup', 'workshop', 'concert', 'sport', 'culture', 'other'
);

create type public.currency_code as enum ('EUR', 'USD', 'MGA');

create type public.reservation_status as enum ('pending', 'confirmed', 'cancelled');

create type public.payment_status as enum (
  'pending', 'paid', 'refunded', 'expired', 'cancelled', 'failed', 'refund_failed'
);

create type public.cancellation_origin as enum (
  'participant', 'moderation', 'account_deleted', 'system'
);

create type public.invitation_status as enum ('pending', 'accepted', 'declined');

create type public.report_target as enum ('event', 'user', 'review');

create type public.report_reason as enum (
  'spam', 'misleading', 'inappropriate', 'fraud', 'harassment', 'other'
);

create type public.moderation_status as enum ('open', 'resolved', 'dismissed');

create type public.moderation_action as enum (
  'hide', 'restore', 'removeEvent', 'suspend', 'reinstate', 'dismiss'
);

-- Contract with the app: lib/features/notifications/application/notification_route.dart
create type public.notification_type as enum (
  'booking', 'cancellation', 'reminder', 'waitlist', 'newEvent', 'eventRemoved',
  'reviewHidden', 'staffInvite', 'staffJoined', 'staffRemoved',
  'paymentConfirmed', 'paymentRefunded'
);

create type public.device_platform as enum ('android', 'ios', 'web');

-- --------------------------------------------------------------- errors ---

-- Raises a business error. `p_status` becomes the HTTP status (PT409 → 409).
create function private.fail(p_status integer, p_rule text, p_message text)
returns void
language plpgsql
as $$
begin
  raise exception using
    errcode = 'PT' || p_status::text,
    message = p_message,
    hint = p_rule;
end;
$$;

-- Raises a validation error carrying `{field: message}` in `detail`.
create function private.fail_validation(p_errors jsonb)
returns void
language plpgsql
as $$
begin
  raise exception using
    errcode = 'PT422',
    message = 'Certains champs sont invalides.',
    hint = 'validation',
    detail = p_errors::text;
end;
$$;

-- -------------------------------------------------------------- parsing ---

create function private.try_uuid(p_value text)
returns uuid
language plpgsql
immutable
as $$
begin
  return p_value::uuid;
exception when others then
  return null;
end;
$$;

-- A JSON integer, or null for anything else (floats with a fraction,
-- strings, out-of-range numbers).
create function private.json_int(p_value jsonb)
returns integer
language plpgsql
immutable
as $$
declare
  v_number numeric;
begin
  if p_value is null or jsonb_typeof(p_value) <> 'number' then
    return null;
  end if;
  v_number := (p_value #>> '{}')::numeric;
  if v_number <> trunc(v_number) or abs(v_number) > 2147483647 then
    return null;
  end if;
  return v_number::integer;
end;
$$;

-- ---------------------------------------------------------------- audit ---

-- Append-only trail of every decision and money movement. Kept a year
-- (purged by the `eventhub-purge` job), never readable through the API.
create table private.audit_log (
  id bigint generated always as identity primary key,
  action text not null,
  actor_id uuid,
  details jsonb not null default '{}'::jsonb,
  at timestamptz not null default now()
);

create index audit_log_at_idx on private.audit_log (at);
create index audit_log_action_idx on private.audit_log (action, at desc);

create function private.audit(p_action text, p_details jsonb default '{}'::jsonb)
returns void
language sql
as $$
  insert into private.audit_log (action, actor_id, details)
  values (p_action, auth.uid(), coalesce(p_details, '{}'::jsonb));
$$;

-- ------------------------------------------------------- rate limiting ---

-- Fixed-window counters. Unlogged: losing them on a crash only resets
-- windows, and it keeps the write path cheap.
create unlogged table private.rate_limits (
  bucket text not null,
  window_start timestamptz not null,
  hits integer not null default 0,
  primary key (bucket, window_start)
);

create function private.throttle(p_bucket text, p_max integer, p_window interval)
returns void
language plpgsql
as $$
declare
  v_window timestamptz := date_bin(p_window, now(), timestamptz '2000-01-01 00:00:00+00');
  v_hits integer;
begin
  -- Read-only transactions (GET requests, STABLE RPCs) cannot count.
  if current_setting('transaction_read_only') = 'on' then
    return;
  end if;
  insert into private.rate_limits as r (bucket, window_start, hits)
  values (p_bucket, v_window, 1)
  on conflict (bucket, window_start) do update set hits = r.hits + 1
  returning r.hits into v_hits;

  if v_hits > p_max then
    perform private.fail(429, 'tooManyRequests', 'Trop de requêtes. Réessayez dans un instant.');
  end if;
end;
$$;

-- ----------------------------------------------------------- formatting ---

-- Notifications are phrased in the organizers' time zone, in French.
create function private.local_time(p_at timestamptz)
returns timestamp
language sql
stable
as $$
  select p_at at time zone 'Indian/Antananarivo';
$$;

-- "18:30"
create function private.fr_time(p_at timestamptz)
returns text
language sql
stable
as $$
  select to_char(private.local_time(p_at), 'HH24:MI');
$$;

-- "samedi 14 septembre à 18:30" — built by hand: the server's lc_time is
-- not French, and `TM` month names would come out in English.
create function private.fr_datetime(p_at timestamptz)
returns text
language sql
stable
as $$
  select (array['dimanche', 'lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi'])
           [extract(dow from l)::integer + 1]
         || ' ' || extract(day from l)::integer || ' '
         || (array['janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet',
                   'août', 'septembre', 'octobre', 'novembre', 'décembre'])
           [extract(month from l)::integer]
         || ' à ' || to_char(l, 'HH24:MI')
  from (select private.local_time(p_at) as l) t;
$$;

-- "Jean-Marc Rakotomalala" → "Jean-Marc R."; a single word stays whole;
-- a deleted account yields null (never shown in social proof).
create function private.short_name(p_name text)
returns text
language sql
immutable
as $$
  select case
    when p_name is null or btrim(p_name) = '' or p_name = 'Compte supprimé' then null
    when array_length(parts, 1) > 1 then
      left(parts[1], 30) || ' ' || upper(left(parts[array_length(parts, 1)], 1)) || '.'
    else left(parts[1], 30)
  end
  from (select regexp_split_to_array(btrim(coalesce(p_name, '')), '\s+') as parts) s;
$$;

create function private.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;
