/**
 * Firebase Cloud Messaging, HTTP v1. FCM stays the push transport (Supabase
 * has none); the database decides who is told what, this only delivers.
 *
 * Credentials: a Firebase service account with the "Firebase Cloud
 * Messaging API Admin" role, as JSON in the `FCM_SERVICE_ACCOUNT` secret.
 * The OAuth token is minted with Web Crypto (RS256) and cached ~1 hour.
 */
import { requireEnv } from './http.ts';

interface ServiceAccount {
  project_id: string;
  client_email: string;
  private_key: string;
}

export interface PushMessage {
  title: string;
  body: string;
  data: Record<string, string>;
}

export interface PushResult {
  sent: number;
  /** Tokens FCM will never accept again: their devices are forgotten. */
  stale: string[];
  /** Transient failures (quota, FCM outage). */
  retryable: number;
}

/** Must match the channel created by the app and AndroidManifest.xml. */
const ANDROID_CHANNEL = 'eventhub_default';

let cachedToken: { value: string; expiresAt: number } | null = null;

function serviceAccount(): ServiceAccount {
  const account = JSON.parse(requireEnv('FCM_SERVICE_ACCOUNT')) as ServiceAccount;
  if (!account.project_id || !account.client_email || !account.private_key) {
    throw new Error('FCM_SERVICE_ACCOUNT is incomplete');
  }
  return account;
}

function base64Url(bytes: Uint8Array): string {
  let binary = '';
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

function pemToDer(pem: string): ArrayBuffer {
  const base64 = pem.replace(/-----(BEGIN|END) PRIVATE KEY-----/g, '').replace(/\s+/g, '');
  const binary = atob(base64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes.buffer;
}

async function accessToken(account: ServiceAccount): Promise<string> {
  if (cachedToken && cachedToken.expiresAt > Date.now() + 60_000) {
    return cachedToken.value;
  }
  const now = Math.floor(Date.now() / 1000);
  const encoder = new TextEncoder();
  const header = base64Url(encoder.encode(JSON.stringify({ alg: 'RS256', typ: 'JWT' })));
  const claims = base64Url(encoder.encode(JSON.stringify({
    iss: account.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  })));
  const key = await crypto.subtle.importKey(
    'pkcs8',
    pemToDer(account.private_key),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const signature = new Uint8Array(
    await crypto.subtle.sign('RSASSA-PKCS1-v1_5', key, encoder.encode(`${header}.${claims}`)),
  );

  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: `${header}.${claims}.${base64Url(signature)}`,
    }),
  });
  if (!response.ok) {
    throw new Error(`FCM OAuth token refused: ${response.status} ${await response.text()}`);
  }
  const { access_token: value, expires_in: expiresIn } = await response.json();
  cachedToken = { value, expiresAt: Date.now() + Number(expiresIn) * 1000 };
  return value;
}

export async function sendPush(message: PushMessage, tokens: string[]): Promise<PushResult> {
  const result: PushResult = { sent: 0, stale: [], retryable: 0 };
  if (tokens.length === 0) return result;

  const account = serviceAccount();
  const bearer = await accessToken(account);
  const url = `https://fcm.googleapis.com/v1/projects/${account.project_id}/messages:send`;

  await Promise.all(tokens.map(async (token) => {
    const response = await fetch(url, {
      method: 'POST',
      headers: { Authorization: `Bearer ${bearer}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        message: {
          token,
          notification: { title: message.title, body: message.body },
          data: message.data,
          android: { priority: 'HIGH', notification: { channel_id: ANDROID_CHANNEL } },
          apns: { payload: { aps: { sound: 'default' } } },
        },
      }),
    });
    if (response.ok) {
      result.sent++;
      return;
    }
    const error = await response.json().catch(() => ({})) as {
      error?: { status?: string; details?: Array<{ errorCode?: string }> };
    };
    const codes = (error.error?.details ?? []).map((d) => d.errorCode);
    if (response.status === 404 || codes.includes('UNREGISTERED') ||
      (response.status === 400 && error.error?.status === 'INVALID_ARGUMENT')) {
      result.stale.push(token);
    } else {
      result.retryable++;
    }
  }));
  return result;
}
