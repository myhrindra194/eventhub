-- =============================================================================
--  EventHub · 7/8 · Job queue and schedules
--  The outbox the `worker` Edge Function drains (push, refunds, Storage
--  clean-up), and the pg_cron jobs that replace Cloud Scheduler.
--
--  Wiring (once per project, see README §3.1):
--    select vault.create_secret('https://<ref>.supabase.co/functions/v1', 'eventhub_functions_url');
--    select vault.create_secret('<random>', 'eventhub_worker_secret');
--  and the same secret in the functions: `supabase secrets set WORKER_SECRET=<random>`.
--  Without them the queue still fills; the one-minute schedule is then the
--  only thing that can drain it, and it is a no-op too — nothing is lost.
-- =============================================================================

-- ====================================================== worker wake-up ===

-- Asks the worker to run now. pg_net sends the request after the current
-- transaction commits, so a rolled-back write never wakes it.
create or replace function private.kick_worker()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_url text;
  v_secret text;
begin
  select s.decrypted_secret into v_url
  from vault.decrypted_secrets s where s.name = 'eventhub_functions_url';
  select s.decrypted_secret into v_secret
  from vault.decrypted_secrets s where s.name = 'eventhub_worker_secret';
  if v_url is null or v_secret is null then
    return;
  end if;

  perform net.http_post(
    url := rtrim(v_url, '/') || '/worker',
    headers := jsonb_build_object('Content-Type', 'application/json', 'x-worker-secret', v_secret),
    body := '{}'::jsonb,
    timeout_milliseconds := 10000
  );
exception when others then
  -- Waking the worker is best effort: the schedule below retries.
  raise warning 'kick_worker: %', sqlerrm;
end;
$$;

create function private.kick_worker_if_due()
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if exists (
    select 1 from private.jobs j
    where (j.status = 'queued' and j.run_after <= now())
       or (j.status = 'running' and j.locked_until < now())
  ) then
    perform private.kick_worker();
  end if;
end;
$$;

-- ======================================================== worker API ===

-- Claims up to `p_limit` due jobs. `skip locked` lets several worker
-- invocations run side by side without taking the same job; a job whose
-- worker died is claimed again once its lock expires.
create function public.jobs_claim(p_limit integer default 25)
returns jsonb
language sql
security definer
set search_path = ''
as $$
  with due as (
    select j.id
    from private.jobs j
    where (j.status = 'queued' and j.run_after <= now())
       or (j.status = 'running' and j.locked_until < now())
    order by j.run_after, j.id
    limit least(greatest(coalesce(p_limit, 25), 1), 100)
    for update skip locked
  ), claimed as (
    update private.jobs j
    set status = 'running', attempts = j.attempts + 1, locked_until = now() + interval '2 minutes'
    from due
    where j.id = due.id
    returning j.id, j.kind, j.payload, j.attempts
  )
  select coalesce(jsonb_agg(jsonb_build_object(
    'id', c.id, 'kind', c.kind, 'payload', c.payload, 'attempts', c.attempts) order by c.id), '[]'::jsonb)
  from claimed c;
$$;

create function public.jobs_complete(p_job_id bigint)
returns void
language sql
security definer
set search_path = ''
as $$
  update private.jobs
  set status = 'done', finished_at = now(), locked_until = null, last_error = null
  where id = p_job_id;
$$;

-- Exponential back-off (1, 2, 4 … 60 minutes), 8 attempts. A refund that
-- finally fails flags its reservation `refund_failed` for a human.
create function public.jobs_fail(p_job_id bigint, p_error text)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_job private.jobs%rowtype;
begin
  update private.jobs j
  set status = case when j.attempts >= 8 then 'failed' else 'queued' end,
      last_error = left(coalesce(p_error, 'unknown'), 2000),
      locked_until = null,
      run_after = now() + least(interval '1 minute' * power(2, greatest(j.attempts - 1, 0)), interval '1 hour'),
      finished_at = case when j.attempts >= 8 then now() end
  where j.id = p_job_id
  returning * into v_job;

  if v_job.status = 'failed' then
    perform private.audit('job.failed', jsonb_build_object(
      'job_id', v_job.id, 'kind', v_job.kind, 'payload', v_job.payload, 'error', v_job.last_error));
    if v_job.kind = 'refund' then
      update public.reservations
      set payment_status = 'refund_failed'
      where id = private.try_uuid(v_job.payload ->> 'reservation_id');
    end if;
  end if;
  return v_job.status;
end;
$$;

-- What the worker needs to push one notification: the message and the
-- recipient's current device tokens. Null when the notification is gone.
create function public.push_payload(p_notification_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'title', n.title,
    'body', n.body,
    'data', jsonb_build_object(
      'type', n.type,
      'notificationId', n.id,
      'eventId', coalesce(n.event_id::text, ''),
      'reservationId', coalesce(n.reservation_id::text, '')
    ),
    'tokens', coalesce((
      select jsonb_agg(jsonb_build_object('token', d.token, 'platform', d.platform))
      from public.devices d where d.user_id = n.user_id
    ), '[]'::jsonb)
  )
  from public.notifications n
  where n.id = p_notification_id;
$$;

-- Tokens FCM will never accept again.
create function public.devices_forget_tokens(p_tokens text[])
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_count integer;
begin
  delete from public.devices where token = any (p_tokens);
  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

-- The public page of an event (F-08): only what an organizer publishes to
-- be shared, nothing about attendees.
create function public.public_event_snapshot(p_event_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'id', e.id,
    'title', e.title,
    'description', e.description,
    'category', e.category,
    'starts_at', e.starts_at,
    'location', e.location,
    'organizer_name', e.organizer_name,
    'image_url', e.image_url,
    'capacity', e.capacity,
    'available_places', e.available_places,
    'currency', e.currency,
    'prices', coalesce((
      select jsonb_agg(t.price order by t.position) from public.event_tiers t where t.event_id = e.id
    ), '[]'::jsonb)
  )
  from public.events e
  where e.id = p_event_id;
$$;

-- ===================================================== scheduled work ===

-- Day-before reminders. `reminder_sent_at` makes a run idempotent and lets
-- a delayed run catch up: every confirmed seat starting within the next
-- 22–24 hours that was not reminded yet.
create function private.send_event_reminders(p_now timestamptz default now())
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_res record;
  v_sent integer := 0;
begin
  for v_res in
    update public.reservations r
    set reminder_sent_at = p_now
    where r.status = 'confirmed'
      and r.reminder_sent_at is null
      and r.user_id is not null
      and r.event_starts_at >= p_now + interval '22 hours'
      and r.event_starts_at < p_now + interval '24 hours'
    returning r.id, r.user_id, r.event_id, r.event_title, r.event_location, r.event_starts_at
  loop
    if private.notify(
      v_res.user_id, 'reminder', 'Demain : ' || v_res.event_title,
      'Rendez-vous à ' || private.fr_time(v_res.event_starts_at) || ' · ' || v_res.event_location
        || '. Votre billet est dans l''application.',
      v_res.event_id, v_res.id, 'event_reminders'
    ) then
      v_sent := v_sent + 1;
    end if;
  end loop;
  return v_sent;
end;
$$;

-- Retention: notifications 30 days, audit 1 year, finished jobs 7 days,
-- rate-limit windows 1 day.
create function private.purge_expired()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_notifications integer;
  v_audit integer;
  v_jobs integer;
begin
  delete from public.notifications where expires_at < now();
  get diagnostics v_notifications = row_count;
  delete from private.audit_log where at < now() - interval '1 year';
  get diagnostics v_audit = row_count;
  delete from private.jobs where status in ('done', 'failed') and finished_at < now() - interval '7 days';
  get diagnostics v_jobs = row_count;
  delete from private.rate_limits where window_start < now() - interval '1 day';
  return jsonb_build_object('notifications', v_notifications, 'audit', v_audit, 'jobs', v_jobs);
end;
$$;

select cron.schedule('eventhub-event-reminders', '5 * * * *', 'select private.send_event_reminders(now())');
select cron.schedule('eventhub-release-holds', '*/10 * * * *', 'select private.release_expired_holds(now())');
select cron.schedule('eventhub-worker', '* * * * *', 'select private.kick_worker_if_due()');
select cron.schedule('eventhub-purge', '17 3 * * *', 'select private.purge_expired()');
