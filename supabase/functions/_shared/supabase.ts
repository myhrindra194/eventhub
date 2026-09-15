import { createClient } from './deps.ts';

/**
 * Service-role client. It bypasses RLS, so it only ever calls the
 * `payments_*`, `jobs_*` and snapshot RPCs, which are executable by the
 * service role alone and re-check every rule themselves.
 * SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are provided by the runtime.
 */
export const admin = createClient(
  Deno.env.get('SUPABASE_URL') ?? '',
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
  { auth: { persistSession: false, autoRefreshToken: false } },
);

/** Calls an RPC; a database error is rethrown for the middleware to map. */
export async function rpc<T>(fn: string, args: Record<string, unknown> = {}): Promise<T> {
  const { data, error } = await admin.rpc(fn, args);
  if (error) throw error;
  return data as T;
}
