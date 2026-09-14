#!/usr/bin/env node
// Grants (or revokes) the `admin` custom claim from a terminal.
//
//   make grant-admin EMAIL=moderation@example.com
//   make grant-admin EMAIL=moderation@example.com REVOKE=1
//   node functions/scripts/grant-admin.mjs <email> [--revoke] [--project <id>]
//
// This is how the FIRST administrator is created: the in-app screen and the
// `setAdminRole` callable both require an existing admin. It runs the exact
// same code as the callable (`applyAdminClaim` in functions/src/index.ts).
//
// Credentials: the Admin SDK uses Application Default Credentials. Once per
// machine: `gcloud auth application-default login` (an account with the
// "Firebase Admin" role on the project), or point GOOGLE_APPLICATION_CREDENTIALS
// at a service-account key. Against the emulators, set
// FIREBASE_AUTH_EMULATOR_HOST and FIRESTORE_EMULATOR_HOST instead.

import { existsSync, readFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const require = createRequire(import.meta.url);

const args = process.argv.slice(2);
const email = args.find((a) => !a.startsWith('--') && a.includes('@'));
const revoke = args.includes('--revoke');
const projectFlag = args.indexOf('--project');

function defaultProject() {
  const rc = join(here, '..', '..', '.firebaserc');
  if (!existsSync(rc)) return undefined;
  return JSON.parse(readFileSync(rc, 'utf8')).projects?.default;
}

const projectId =
  (projectFlag >= 0 ? args[projectFlag + 1] : undefined) ?? defaultProject();

if (!email || !projectId) {
  console.error(
    'Usage: node functions/scripts/grant-admin.mjs <email> [--revoke] [--project <id>]',
  );
  process.exit(64);
}

const compiled = join(here, '..', 'lib', 'index.js');
if (!existsSync(compiled)) {
  console.error('Compile the functions first: npm --prefix functions run build');
  process.exit(1);
}

// functions/src/index.ts initialises the default app from these variables.
process.env.GCLOUD_PROJECT = projectId;
process.env.GOOGLE_CLOUD_PROJECT = projectId;

const { applyAdminClaim } = require(compiled);
const { getAuth } = require('firebase-admin/auth');

try {
  const user = await getAuth().getUserByEmail(email.trim().toLowerCase());
  await applyAdminClaim(user.uid, !revoke, 'cli');
  console.log(
    `${revoke ? 'Rôle admin retiré à' : 'Rôle admin accordé à'} ${user.email} ` +
      `(${user.uid}) sur ${projectId}.`,
  );
  console.log(
    'La personne doit se déconnecter puis se reconnecter pour que le rôle ' +
      'soit pris en compte.',
  );
  process.exit(0);
} catch (error) {
  if (error?.code === 'auth/user-not-found') {
    console.error(`Aucun compte ${email} sur ${projectId} : créez-le d'abord dans l'app.`);
  } else {
    console.error(error?.message ?? error);
    console.error(
      'Identifiants : gcloud auth application-default login, ou ' +
        'GOOGLE_APPLICATION_CREDENTIALS=<clé de compte de service>.',
    );
  }
  process.exit(1);
}
