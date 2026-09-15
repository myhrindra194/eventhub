import { createHash } from 'node:crypto';

/** The organizer lookup key the rules expect: sha256(lowercase email), hex. */
export const emailKey = (email) => createHash('sha256').update(email.toLowerCase()).digest('hex');
