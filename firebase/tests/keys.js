import { createHash } from 'node:crypto';

/** La clé de recherche organisateur attendue : sha256(e-mail minuscule), hexa. */
export const emailKey = (email) => createHash('sha256').update(email.toLowerCase()).digest('hex');
