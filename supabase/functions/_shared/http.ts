/**
 * The middleware pipeline every EventHub Edge Function runs through.
 *
 *   request id → CORS preflight → method check → authentication
 *   (user JWT · worker secret · public) → JSON body (size-capped) →
 *   handler → uniform error response → structured log line
 *
 * Errors leave in the same shape PostgREST uses for the RPCs —
 * `{code: "PT409", message, hint: <rule>, details}` — so the app maps a
 * function failure and a database failure with one code path
 * (lib/core/errors/error_mapper.dart).
 */
import { admin } from './supabase.ts';
import type { User } from './deps.ts';

export class HttpError extends Error {
  constructor(
    readonly status: number,
    readonly rule: string,
    message: string,
    readonly details?: Record<string, unknown>,
  ) {
    super(message);
  }
}

export const corsHeaders: Record<string, string> = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-request-id',
  'Access-Control-Allow-Methods': 'GET, HEAD, POST, OPTIONS',
  'Access-Control-Max-Age': '86400',
};

export function json(body: unknown, status = 200, headers: Record<string, string> = {}): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json; charset=utf-8', ...headers },
  });
}

export interface Logger {
  info(message: string, fields?: Record<string, unknown>): void;
  warn(message: string, fields?: Record<string, unknown>): void;
  error(message: string, fields?: Record<string, unknown>): void;
}

function logger(fn: string, requestId: string): Logger {
  const write = (level: string, message: string, fields: Record<string, unknown> = {}) =>
    console[level === 'error' ? 'error' : level === 'warn' ? 'warn' : 'log'](
      JSON.stringify({ level, fn, requestId, message, ...fields, at: new Date().toISOString() }),
    );
  return {
    info: (m, f) => write('info', m, f),
    warn: (m, f) => write('warn', m, f),
    error: (m, f) => write('error', m, f),
  };
}

export interface Context {
  request: Request;
  requestId: string;
  /** The signed-in caller (auth: 'user'), null otherwise. */
  user: User | null;
  /** Parsed JSON body of a POST; empty otherwise or when `rawBody`. */
  body: Record<string, unknown>;
  log: Logger;
}

export interface Options {
  methods: Array<'GET' | 'HEAD' | 'POST'>;
  auth: 'user' | 'worker' | 'public';
  /** Leave the body unread (signature checks need the exact bytes). */
  rawBody?: boolean;
  maxBodyBytes?: number;
}

export function serve(name: string, options: Options, handler: (ctx: Context) => Promise<Response>): void {
  Deno.serve(async (request) => {
    const requestId = request.headers.get('x-request-id') ?? crypto.randomUUID();
    const log = logger(name, requestId);
    const started = performance.now();
    let userId: string | undefined;

    try {
      if (request.method === 'OPTIONS') {
        return new Response(null, { status: 204, headers: corsHeaders });
      }
      if (!(options.methods as string[]).includes(request.method)) {
        throw new HttpError(405, 'methodNotAllowed', 'Méthode non autorisée.');
      }

      let user: User | null = null;
      if (options.auth === 'user') {
        user = await authenticate(request);
        userId = user.id;
      } else if (options.auth === 'worker') {
        verifyWorkerSecret(request);
      }

      const body = request.method === 'POST' && !options.rawBody
        ? await readJson(request, options.maxBodyBytes ?? 16 * 1024)
        : {};

      const response = await handler({ request, requestId, user, body, log });
      response.headers.set('x-request-id', requestId);
      log.info('handled', { status: response.status, userId, ms: Math.round(performance.now() - started) });
      return response;
    } catch (error) {
      const failure = toHttpError(error);
      const fields = {
        status: failure.status,
        rule: failure.rule,
        userId,
        ms: Math.round(performance.now() - started),
        cause: describe(error),
      };
      if (failure.status >= 500) log.error('failed', fields);
      else log.warn('refused', fields);
      return json(
        { code: `PT${failure.status}`, message: failure.message, hint: failure.rule, details: failure.details ?? null },
        failure.status,
        { 'x-request-id': requestId },
      );
    }
  });
}

async function authenticate(request: Request): Promise<User> {
  const header = request.headers.get('Authorization') ?? '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : '';
  if (!token) {
    throw new HttpError(401, 'notSignedIn', 'Vous devez être connecté.');
  }
  const { data, error } = await admin.auth.getUser(token);
  if (error || !data.user) {
    throw new HttpError(401, 'notSignedIn', 'Session expirée : reconnectez-vous.');
  }
  const bannedUntil = (data.user as User & { banned_until?: string }).banned_until;
  if (bannedUntil && new Date(bannedUntil) > new Date()) {
    throw new HttpError(403, 'accountSuspended', 'Ce compte est suspendu par la modération.');
  }
  return data.user;
}

function verifyWorkerSecret(request: Request): void {
  const expected = Deno.env.get('WORKER_SECRET') ?? '';
  const given = request.headers.get('x-worker-secret') ?? '';
  if (!expected || !timingSafeEqual(expected, given)) {
    throw new HttpError(401, 'notSignedIn', 'Accès refusé.');
  }
}

function timingSafeEqual(a: string, b: string): boolean {
  const left = new TextEncoder().encode(a);
  const right = new TextEncoder().encode(b);
  let diff = left.length ^ right.length;
  for (let i = 0; i < Math.max(left.length, right.length); i++) {
    diff |= (left[i] ?? 0) ^ (right[i] ?? 0);
  }
  return diff === 0;
}

async function readJson(request: Request, maxBytes: number): Promise<Record<string, unknown>> {
  const declared = Number(request.headers.get('content-length') ?? 0);
  if (declared > maxBytes) {
    throw new HttpError(413, 'payloadTooLarge', 'Requête trop volumineuse.');
  }
  const text = await request.text();
  if (new TextEncoder().encode(text).length > maxBytes) {
    throw new HttpError(413, 'payloadTooLarge', 'Requête trop volumineuse.');
  }
  if (!text.trim()) return {};
  try {
    const value = JSON.parse(text);
    if (value === null || typeof value !== 'object' || Array.isArray(value)) throw new Error('not an object');
    return value as Record<string, unknown>;
  } catch {
    throw new HttpError(400, 'validation', 'Requête invalide.');
  }
}

/** HttpError as is; database errors by their SQLSTATE; anything else hidden. */
export function toHttpError(error: unknown): HttpError {
  if (error instanceof HttpError) return error;

  const e = error as { code?: string; message?: string; hint?: string; details?: string; type?: string };
  if (typeof e?.code === 'string') {
    const custom = /^PT(\d{3})$/.exec(e.code);
    if (custom) {
      let details: Record<string, unknown> | undefined;
      try {
        details = e.details ? JSON.parse(e.details) : undefined;
      } catch {
        details = undefined;
      }
      return new HttpError(Number(custom[1]), e.hint ?? 'actionRefused', e.message ?? 'Action refusée.', details);
    }
    if (e.code === '42501') return new HttpError(403, 'permissionDenied', "Vous n'avez pas les droits pour cette action.");
    if (e.code === '23505') return new HttpError(409, 'conflict', 'Cette opération a déjà été faite.');
  }
  if (typeof e?.type === 'string' && e.type.startsWith('Stripe')) {
    return new HttpError(502, 'paymentUnavailable', 'Le paiement est indisponible pour le moment. Réessayez plus tard.');
  }
  return new HttpError(500, 'unexpected', 'Une erreur inattendue est survenue.');
}

export function describe(error: unknown): string {
  if (error instanceof Error) return `${error.name}: ${error.message}`;
  try {
    return JSON.stringify(error);
  } catch {
    return String(error);
  }
}

export function requireEnv(name: string): string {
  const value = Deno.env.get(name);
  if (!value) {
    throw new HttpError(503, 'notConfigured', 'Service indisponible : configuration incomplète.');
  }
  return value;
}

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export function isUuid(value: unknown): value is string {
  return typeof value === 'string' && UUID.test(value);
}

/** A required uuid field of the body, or a 422 naming it. */
export function uuidField(body: Record<string, unknown>, key: string, label: string): string {
  const value = body[key];
  if (!isUuid(value)) {
    throw new HttpError(422, 'validation', `${label} invalide.`, { [key]: `${label} invalide.` });
  }
  return value;
}
