/**
 * Drains the `private.jobs` outbox: push delivery, queued refunds, Storage
 * clean-up. Woken by the database (pg_net, right after a commit) and every
 * minute by pg_cron; authenticated by the shared `x-worker-secret`.
 *
 * Jobs are claimed with `for update skip locked`, so overlapping runs never
 * process the same job. A failed job is retried with exponential back-off
 * (jobs_fail) and, after 8 attempts, parked as `failed` — a refund that
 * never succeeds flags its reservation `refund_failed` for a human.
 */
import { sendPush, type PushMessage } from '../_shared/fcm.ts';
import { describe, json, serve } from '../_shared/http.ts';
import { refundPaymentIntent } from '../_shared/stripe.ts';
import { admin, rpc } from '../_shared/supabase.ts';

interface Job {
  id: number;
  kind: 'push' | 'refund' | 'storage.delete';
  payload: Record<string, unknown>;
  attempts: number;
}

/** Stay well inside the Edge Function wall-clock limit. */
const BUDGET_MS = 40_000;
const BATCH = 25;
const BUCKETS = new Set(['event-covers', 'avatars']);

serve('worker', { methods: ['POST'], auth: 'worker' }, async ({ log }) => {
  const deadline = Date.now() + BUDGET_MS;
  const summary = { done: 0, retried: 0, failed: 0 };

  while (Date.now() < deadline) {
    const jobs = await rpc<Job[]>('jobs_claim', { p_limit: BATCH });
    if (jobs.length === 0) break;

    await Promise.all(jobs.map(async (job) => {
      try {
        await run(job);
        await rpc('jobs_complete', { p_job_id: job.id });
        summary.done++;
      } catch (error) {
        const status = await rpc<string>('jobs_fail', { p_job_id: job.id, p_error: describe(error) });
        if (status === 'failed') summary.failed++;
        else summary.retried++;
        log.warn('job failed', { jobId: job.id, kind: job.kind, attempts: job.attempts, status, error: describe(error) });
      }
    }));
    if (jobs.length < BATCH) break;
  }
  return json(summary);
});

async function run(job: Job): Promise<void> {
  switch (job.kind) {
    case 'push':
      return push(String(job.payload.notification_id));
    case 'refund':
      return refund(job.payload);
    case 'storage.delete':
      return deleteFiles(job.payload);
  }
}

async function push(notificationId: string): Promise<void> {
  const payload = await rpc<(PushMessage & { tokens: Array<{ token: string }> }) | null>('push_payload', {
    p_notification_id: notificationId,
  });
  // Deleted notification or no device left: nothing to deliver.
  if (!payload || payload.tokens.length === 0) return;

  const result = await sendPush(
    { title: payload.title, body: payload.body, data: payload.data },
    payload.tokens.map((t) => t.token),
  );
  if (result.stale.length > 0) {
    await rpc('devices_forget_tokens', { p_tokens: result.stale });
  }
  // Retry only when nobody got it: a partial retry would push twice.
  if (result.sent === 0 && result.retryable > 0) {
    throw new Error(`FCM unavailable for ${result.retryable} device(s)`);
  }
}

async function refund(payload: Record<string, unknown>): Promise<void> {
  const reservationId = String(payload.reservation_id);
  const paymentIntentId = String(payload.payment_intent_id);
  const refundId = await refundPaymentIntent(paymentIntentId, reservationId, String(payload.context ?? 'queue'));
  await rpc('payments_refund_settled', { p_reservation_id: reservationId, p_refund_id: refundId });
}

async function deleteFiles(payload: Record<string, unknown>): Promise<void> {
  const bucket = String(payload.bucket);
  if (!BUCKETS.has(bucket)) throw new Error(`unknown bucket ${bucket}`);
  const storage = admin.storage.from(bucket);

  if (Array.isArray(payload.paths)) {
    const paths = payload.paths.map(String).filter((p) => p && !p.includes('..'));
    if (paths.length === 0) return;
    const { error } = await storage.remove(paths);
    if (error) throw error;
    return;
  }

  // A whole user folder (`<uid>/`), page by page.
  const folder = String(payload.prefix ?? '').replace(/\/+$/, '');
  if (!/^[0-9a-f-]{36}$/i.test(folder)) throw new Error(`refusing prefix ${folder}`);
  for (;;) {
    const { data, error } = await storage.list(folder, { limit: 100 });
    if (error) throw error;
    if (!data || data.length === 0) return;
    const { error: removeError } = await storage.remove(data.map((f) => `${folder}/${f.name}`));
    if (removeError) throw removeError;
    if (data.length < 100) return;
  }
}
