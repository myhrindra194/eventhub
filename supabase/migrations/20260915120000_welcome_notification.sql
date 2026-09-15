-- =============================================================================
--  EventHub · 12 · Welcome notification at the first sign-in
-- =============================================================================
--  A push needs a device token tied to the account, and a device is only
--  registered once someone is signed in — with email confirmation there is
--  no session at sign-up. The welcome therefore goes out when the account
--  registers its first device: right after the first sign-in, in the same
--  transaction, once per account (profiles.welcomed_at, not client-writable),
--  worded for the role. Email already covers the sign-up moment itself.
-- =============================================================================

alter type public.notification_type add value if not exists 'welcome';

alter table public.profiles add column welcomed_at timestamptz;

create or replace function public.register_device(
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
  v_profile public.profiles%rowtype;
  v_first_name text;
begin
  perform private.throttle('device:' || v_uid::text, 20, interval '1 minute');
  delete from public.devices where token = p_token and user_id <> v_uid;
  insert into public.devices (user_id, device_id, token, platform, locale, updated_at)
  values (v_uid, p_device_id, p_token, p_platform, nullif(btrim(coalesce(p_locale, '')), ''), now())
  on conflict (user_id, device_id) do update
  set token = excluded.token, platform = excluded.platform, locale = excluded.locale, updated_at = now();

  -- Locked: two devices signing in at the same instant welcome once.
  select * into v_profile from public.profiles p where p.id = v_uid for update;
  if found and v_profile.welcomed_at is null then
    update public.profiles set welcomed_at = now() where id = v_uid;
    v_first_name := split_part(btrim(v_profile.name), ' ', 1);
    perform private.notify(
      v_uid,
      'welcome',
      'Bienvenue sur EventHub, ' || v_first_name,
      case v_profile.role
        when 'organizer' then
          'Inscription confirmée : vous êtes connecté en organisateur. '
          || 'Publiez votre premier événement, vos abonnés seront prévenus.'
        else
          'Inscription confirmée : vous êtes connecté. '
          || 'Découvrez les événements et réservez votre place en un geste.'
      end
    );
  end if;
end;
$$;
