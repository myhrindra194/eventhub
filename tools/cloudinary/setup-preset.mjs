// Crée — ou remet en conformité — l'upload preset non signé qu'utilise
// l'application Flutter.
//
// Pourquoi un script plutôt que des clics dans la console : les réglages du
// preset sont la seule barrière entre deux valeurs publiques (nom du cloud,
// nom du preset, lisibles dans n'importe quel binaire de l'app) et le compte
// Cloudinary. Les écrire ici les rend relisibles en revue de code, et
// relancer le script corrige un preset modifié à la main par erreur.
//
// Pourquoi sur le poste d'un mainteneur : l'API d'administration exige le
// secret API. Il vit dans `tools/cloudinary/.env` (ignoré par git) et ne doit
// jamais entrer dans l'app, dans `env/*.json` ni dans le dépôt.
//
// Usage : npm run setup-preset   (depuis tools/cloudinary)

import { v2 as cloudinary } from 'cloudinary';

if (!process.env.CLOUDINARY_URL) {
  console.error('CLOUDINARY_URL absent : créez tools/cloudinary/.env (voir docs/SECURITY.md §11).');
  process.exit(1);
}

// Le SDK lit CLOUDINARY_URL tout seul ; `secure` force les URL https.
cloudinary.config({ secure: true });

/** Nom repris tel quel dans `CLOUDINARY_UPLOAD_PRESET` (env/dev.json). */
const PRESET = 'eventhub_unsigned';

const settings = {
  // Envoi depuis l'appareil sans signature : imposé par l'absence de serveur.
  unsigned: true,
  // Jamais d'écrasement : sinon un tiers pourrait remplacer l'image d'un
  // autre compte en réutilisant son public_id.
  overwrite: false,
  unique_filename: true,
  use_filename: false,
  // Pas de SVG (peut porter du script), ni PDF, ni vidéo.
  allowed_formats: 'jpg,jpeg,png,webp,heic',
  // Transformation entrante : la version stockée est déjà bornée à 2 048 px,
  // quel que soit le fichier reçu. Protège le quota de stockage.
  transformation: [{ crop: 'limit', width: 2048, height: 2048 }],
  // Étiquette ajoutée côté serveur, en plus de celles envoyées par l'app :
  // un fichier déposé hors de l'app se retrouve quand même par elle.
  tags: 'eventhub',
};

async function presetExists(name) {
  try {
    await cloudinary.api.upload_preset(name);
    return true;
  } catch (error) {
    if (error?.error?.http_code === 404) return false;
    throw error;
  }
}

try {
  if (await presetExists(PRESET)) {
    await cloudinary.api.update_upload_preset(PRESET, settings);
    console.log(`Preset « ${PRESET} » remis en conformité.`);
  } else {
    await cloudinary.api.create_upload_preset({ name: PRESET, ...settings });
    console.log(`Preset « ${PRESET} » créé.`);
  }
  const { settings: applied } = await cloudinary.api.upload_preset(PRESET);
  console.log(JSON.stringify(applied, null, 2));
} catch (error) {
  // Le SDK renvoie { error: { message, http_code } } ; jamais le secret.
  console.error('Échec :', error?.error?.message ?? error);
  process.exit(1);
}
