// Emails transactionnels : le mail de bienvenue après l'inscription et le
// formulaire « Nous contacter ».
//
// Pourquoi Brevo : son offre gratuite (300 emails par jour) accepte un
// expéditeur vérifié par simple confirmation d'adresse, sans posséder de nom
// de domaine — ce que Resend ou SendGrid exigent pour écrire à n'importe qui.
// L'API est un seul appel HTTPS, donc utilisable depuis un Worker, là où SMTP
// ne l'est pas simplement.
//
// Pourquoi côté serveur : la clé Brevo permet d'écrire à n'importe qui au nom
// de l'entreprise. Dans l'app, elle serait extraite du binaire en une minute.

import { HttpError } from './google.js';

const BREVO_URL = 'https://api.brevo.com/v3/smtp/email';

/// Un message par compte toutes les deux minutes : assez pour corriger une
/// faute de frappe, trop peu pour transformer le formulaire en canon à spam.
export const CONTACT_COOLDOWN_MS = 2 * 60 * 1000;

const SUBJECT_MAX = 120;
const MESSAGE_MAX = 5000;

/// Échappe le texte saisi par l'utilisateur avant de l'insérer dans du HTML :
/// sans cela, un message contenant `<a href=…>` deviendrait un lien cliquable
/// dans la boîte de l'entreprise.
export function escapeHtml(text) {
  return String(text)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

export function createMailer({ apiKey, sender, fetchImpl = fetch }) {
  const configured = Boolean(apiKey && sender);

  return {
    configured,

    async send({ to, subject, text, html, replyTo }) {
      if (!configured) throw new HttpError(503, 'mail_not_configured');
      const response = await fetchImpl(BREVO_URL, {
        method: 'POST',
        headers: { 'api-key': apiKey, 'content-type': 'application/json', accept: 'application/json' },
        body: JSON.stringify({
          sender: { name: 'EventHub', email: sender },
          to: [to],
          subject,
          textContent: text,
          htmlContent: html,
          ...(replyTo ? { replyTo } : {}),
        }),
      });
      if (!response.ok) {
        // Jamais le corps : il peut citer la clé ou l'adresse de l'expéditeur.
        console.warn(`Brevo refused an email (${response.status})`);
        throw new HttpError(502, 'mail_refused');
      }
    },
  };
}

// ----------------------------------------------------------------- gabarits

/// Mail de bienvenue. Le texte brut accompagne toujours le HTML : certains
/// clients (et tous les filtres anti-spam) le lisent en premier.
export function welcomeEmail({ name, appOrigin }) {
  const first = (name || '').trim().split(/\s+/)[0] || 'et bienvenue';
  const link = appOrigin || 'https://eventhub-d411f.web.app';
  const subject = 'Bienvenue sur EventHub';
  const text = [
    `Bonjour ${first},`,
    '',
    'Félicitations, votre inscription sur EventHub est terminée.',
    'Vous pouvez dès maintenant découvrir les événements près de chez vous, réserver votre place et retrouver vos billets dans l’app.',
    '',
    'Organisateur ? Pour publier votre premier événement, nous vous demanderons simplement de confirmer votre adresse email au moment de le faire.',
    '',
    `À très vite sur EventHub : ${link}`,
    '',
    'L’équipe EventHub',
  ].join('\n');
  const html = `<!doctype html>
<html lang="fr"><body style="margin:0;padding:0;background:#F6F6FA;">
<table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background:#F6F6FA;padding:32px 16px;">
<tr><td align="center">
<table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="max-width:520px;background:#FFFFFF;border:1px solid #DCDBE8;border-radius:6px;">
<tr><td style="padding:28px 28px 8px;font:600 13px/1 Arial,sans-serif;letter-spacing:.08em;text-transform:uppercase;color:#564ED4;">EventHub</td></tr>
<tr><td style="padding:8px 28px 0;font:700 24px/1.25 Arial,sans-serif;color:#1B1A2E;">Félicitations, ${escapeHtml(first)} !</td></tr>
<tr><td style="padding:12px 28px 0;font:400 15px/1.6 Arial,sans-serif;color:#3F3D56;">Votre inscription est terminée. Découvrez les événements près de chez vous, réservez votre place et retrouvez vos billets dans l’app.</td></tr>
<tr><td style="padding:12px 28px 0;font:400 15px/1.6 Arial,sans-serif;color:#3F3D56;">Organisateur ? Nous vous demanderons de confirmer votre adresse email au moment de publier votre premier événement.</td></tr>
<tr><td style="padding:24px 28px 28px;"><a href="${escapeHtml(link)}" style="display:inline-block;background:#564ED4;color:#FFFFFF;font:600 15px/1 Arial,sans-serif;text-decoration:none;padding:14px 20px;border-radius:6px;">Ouvrir EventHub</a></td></tr>
</table>
<p style="font:400 12px/1.5 Arial,sans-serif;color:#7D7A99;margin:16px 0 0;">Vous recevez ce message parce qu’un compte EventHub vient d’être créé avec cette adresse.</p>
</td></tr></table></body></html>`;
  return { subject, text, html };
}

/// Message du formulaire « Nous contacter », adressé à la boîte de
/// l'entreprise. `replyTo` pointe vers l'utilisateur : répondre depuis la
/// boîte de l'entreprise lui écrit directement.
export function contactEmail({ subject, message, fromName, fromEmail, uid }) {
  const cleanSubject = String(subject).trim().slice(0, SUBJECT_MAX);
  const cleanMessage = String(message).trim().slice(0, MESSAGE_MAX);
  const text = `${cleanMessage}\n\n—\n${fromName || 'Utilisateur'} <${fromEmail}>\nCompte : ${uid}`;
  const html = `<div style="font:400 15px/1.6 Arial,sans-serif;color:#1B1A2E;white-space:pre-wrap;">${escapeHtml(cleanMessage)}</div>
<hr style="border:0;border-top:1px solid #DCDBE8;margin:20px 0;">
<div style="font:400 13px/1.5 Arial,sans-serif;color:#5F5D78;">${escapeHtml(fromName || 'Utilisateur')} &lt;${escapeHtml(fromEmail)}&gt;<br>Compte : ${escapeHtml(uid)}</div>`;
  return { subject: `[Contact] ${cleanSubject}`, text, html };
}

export function validateContact(body) {
  const subject = typeof body?.subject === 'string' ? body.subject.trim() : '';
  const message = typeof body?.message === 'string' ? body.message.trim() : '';
  if (subject.length < 3 || subject.length > SUBJECT_MAX) throw new HttpError(400, 'bad_subject');
  if (message.length < 10 || message.length > MESSAGE_MAX) throw new HttpError(400, 'bad_message');
  return { subject, message };
}

// ------------------------------------------------------------------ actions

/// Envoie le mail de bienvenue au compte appelant, une seule fois.
///
/// L'adresse vient du jeton Firebase, jamais du corps de la requête : sans
/// cela, n'importe qui pourrait faire écrire l'entreprise à une adresse de
/// son choix. Le reçu `mailReceipts/welcome:{uid}` garantit l'unicité, même
/// si l'app rappelle l'endpoint après un redémarrage.
export async function sendWelcome({ claims, firestore, mailer, now = () => Date.now(), appOrigin }) {
  if (!claims.email) throw new HttpError(400, 'no_email');
  const first = await firestore.createOnce('mailReceipts', `welcome:${claims.sub}`, {
    kind: { stringValue: 'welcome' },
    uid: { stringValue: claims.sub },
    sentAt: { timestampValue: new Date(now()).toISOString() },
  });
  if (!first) return { status: 'already_sent' };

  const profile = await firestore.get(`users/${claims.sub}`);
  const name = profile?.fields?.name?.stringValue ?? claims.name ?? '';
  const { subject, text, html } = welcomeEmail({ name, appOrigin });
  await mailer.send({ to: { email: claims.email, ...(name ? { name } : {}) }, subject, text, html });
  return { status: 'sent' };
}

/// Transmet un message à la boîte de l'entreprise.
export async function sendContact({ claims, request, firestore, mailer, companyEmail, now = () => Date.now() }) {
  if (!companyEmail) throw new HttpError(503, 'mail_not_configured');
  if (!claims.email) throw new HttpError(400, 'no_email');

  // Limitation de débit par compte, adossée à un document par utilisateur.
  const path = `contactThrottle/${claims.sub}`;
  const last = await firestore.get(path);
  const lastAt = Date.parse(last?.fields?.sentAt?.timestampValue ?? '');
  if (Number.isFinite(lastAt) && now() - lastAt < CONTACT_COOLDOWN_MS) {
    throw new HttpError(429, 'too_many_messages');
  }
  await firestore.upsert(path, { sentAt: { timestampValue: new Date(now()).toISOString() } });

  const profile = await firestore.get(`users/${claims.sub}`);
  const fromName = profile?.fields?.name?.stringValue ?? claims.name ?? '';
  const { subject, text, html } = contactEmail({ ...request, fromName, fromEmail: claims.email, uid: claims.sub });
  await mailer.send({
    to: { email: companyEmail, name: 'EventHub' },
    subject,
    text,
    html,
    replyTo: { email: claims.email, ...(fromName ? { name: fromName } : {}) },
  });
  return { status: 'sent' };
}
