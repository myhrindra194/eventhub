-- =============================================================================
--  Wake-up of the `worker` Edge Function — run once per project in
--  Supabase → SQL Editor, after `make functions-deploy`.
-- =============================================================================
--  The database queues push notifications, refunds and Storage clean-ups in
--  private.jobs and calls the worker through pg_net right after each commit
--  (plus once a minute through pg_cron). It needs the functions URL and a
--  shared secret, kept in Vault — never in a migration.
--
--  1. Generate a secret:            openssl rand -hex 32
--  2. Same value in the functions:  WORKER_SECRET=<secret> in supabase/functions/.env,
--                                   then `make secrets-push`
--  3. Replace <project-ref> and <secret> below, run.

select vault.create_secret('https://<project-ref>.supabase.co/functions/v1', 'eventhub_functions_url');
select vault.create_secret('<secret>', 'eventhub_worker_secret');

-- Check: the next minute, cron fires `eventhub-worker`; queued jobs drain.
-- select status, count(*) from private.jobs group by status;
-- select jobname, schedule from cron.job where jobname like 'eventhub-%';

-- Rotate the secret later:
-- select vault.update_secret(
--   (select id from vault.secrets where name = 'eventhub_worker_secret'), '<new secret>');
