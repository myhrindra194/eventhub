# EventHub — Design system « Aurora »

> Ce document décrit le langage visuel de l'application : ses tokens, ses
> composants, et surtout **les décisions** derrière eux. Une décision non
> écrite est une décision qui sera défaite au prochain sprint.

---

## 1. Principe directeur

**Un écran compose, il ne dessine pas.**

Si un écran a besoin d'un `Container` avec une couleur choisie à la main,
c'est qu'un composant manque — et il doit être créé dans
`lib/core/widgets/`, pas inliné. C'est la seule règle qui empêche un design
system de se déliter en six mois.

Conséquence directe : **aucune valeur hexadécimale n'existe en dehors de
`app/theme/app_palette.dart`**. Une couleur y devient une rampe, la rampe
devient un token sémantique, et c'est le token que le widget consomme.

```
app_palette.dart      →  app_tokens.dart      →  widget
(iris500 = #6A63E6)      (brand, danger.fg)      (context.tokens.brand)
     rampes brutes          sens métier           consommation
```

Cette indirection est ce qui rend le thème clair possible **sans toucher un
seul widget** : on échange deux instances de `AppTokens`, rien d'autre.

---

## 2. Tokens

### 2.1 Couleur

Les rampes sont numérotées 50 → 950 (convention Tailwind / Radix).

| Rampe | Rôle | Pourquoi cette teinte |
|---|---|---|
| **Neutral** | Fonds, textes, bordures | Gris légèrement froid. Le noir et le blanc purs vibrent contre les contenus saturés et aplatissent la photographie |
| **Iris** (indigo-violet) | Marque | Assez affirmée pour porter une identité, assez sobre pour ne pas fatiguer ; lisible sur fond clair **et** sombre |
| **Ember** (corail chaud) | Accent | Contrepoids chaud. Utilisé avec parcimonie — jamais comme seconde couleur primaire |
| **Mint / Amber / Rose / Sky** | Sémantique | Succès / attention / danger / information |
| **Violet, Fuchsia, Teal, Lime** | Catégories | Réparties sur la roue chromatique pour rester distinguables à taille de pastille |

**Tokens sémantiques** (`AppTokens`) :

| Groupe | Tokens | Usage |
|---|---|---|
| Fonds | `canvas`, `surface`, `surfaceRaised`, `surfaceSunken`, `surfaceOverlay`, `glass` | `sunken` = creux (champs, pistes de barre) ; `raised` = plus proche de l'utilisateur (menus, barres) |
| Traits | `borderSubtle`, `border`, `borderStrong` | Trois niveaux suffisent ; un quatrième ne se voit pas |
| Texte | `textPrimary`, `textSecondary`, `textTertiary`, `textOnBrand` | |
| Marque | `brand`, `brandSoft`, `brandStrong`, `accent`, `accentSoft` | `brandSoft` est un tint basse opacité pour les fonds de pastilles |
| Statuts | `success`, `warning`, `danger`, `info`, `neutralTone` | Chacun est un `ToneColors { fg, bg, border, solid, onSolid }` |
| Décor | `shadows`, `brandGradient`, `heroScrim`, `bloomPrimary/Secondary`, `skeleton*` | |

Le type `ToneColors` porte une garantie : **`fg` est lisible sur `bg`, et `bg`
est lisible sur le fond de l'écran**. C'est ce qui permet de déposer un
`AppBadge` n'importe où sans refaire un audit de contraste.

### 2.2 Espacement — grille de 4 pt

`none 0 · xxs 2 · xs 4 · sm 8 · md 12 · lg 16 · xl 20 · xxl 24 · xxxl 32 · huge 40 · giant 56`

Plus une constante `gutter = 20` : la marge horizontale de **tous** les
écrans. La changer réaligne l'application entière.

> Une mise en page construite à partir d'une échelle finie se lit comme
> délibérée ; la même construite avec des nombres arbitraires se lit comme
> accidentelle. C'est l'essentiel de ce que « design mature » veut dire.

### 2.3 Rayons

`xs 8 · sm 12 · md 16 · lg 20 · xl 24 · xxl 28 · xxxl 34 · pill 999`

L'échelle est **consciente de l'imbrication** : un enfant dans un conteneur de
rayon `r` prend le cran juste en dessous, ce qui garde les angles concentriques
visuellement parallèles.

### 2.4 Élévation

Pas de `elevation: n` Material. Des **recettes d'ombre** à deux couches (une
ombre de contact serrée + une ombre ambiante large), déclinées par thème :
en sombre, l'élévation numérique de Material ajoute une teinte qui lave les
surfaces au lieu de les soulever.

`SurfaceElevation { flat, low, medium, high }` → `shadows.xs … shadows.lg`

### 2.5 Mouvement

| Token | Durée | Usage |
|---|---|---|
| `instant` | 80 ms | retour d'état (pression) |
| `xshort` | 120 ms | ripple, hover |
| `short` | 180 ms | petit élément qui entre ou sort |
| `medium` | 260 ms | transition de page, carte qui s'ouvre |
| `slow` | 340 ms | feuille modale |
| `long` / `xlong` | 480 / 720 ms | plein écran, célébration |

Courbes : `emphasized` (défaut), `decelerate` (entrée), `accelerate` (sortie),
`standard` (aller-retour), `spring` (célébration uniquement).

### 2.6 Typographie

Appariement **éditorial**, deux familles, un rôle chacune :

- **Plus Jakarta Sans** — display / headline / title. Géométrique avec des
  détails humanistes ; en grande taille et interlettrage serré, elle donne une
  voix au produit au lieu d'un rendu « application Material par défaut ».
- **Inter** — corps, labels, toute chaîne d'interface dense. Dessinée pour
  l'écran : elle tient à 12–14 px là où une display se disloque.

Échelle modulaire ≈ 1,2. Tout ce qui dépasse 20 px reçoit un interlettrage
négatif : un grand texte à l'interlettrage par défaut paraît mou.

`AppTypography.tabular` fournit les chiffres tabulaires — obligatoire pour les
compteurs, capacités et comptes à rebours, sinon la largeur danse à chaque
changement de chiffre.

---

## 3. Thème clair / sombre

Les deux thèmes sont **le même code exécuté sur deux jeux de tokens**
(`AppTheme._build`). Ils ne peuvent donc pas diverger.

- Par défaut : `ThemeMode.system`. Une application qui combat le réglage
  système se fait remarquer pour la mauvaise raison.
- Le choix est persisté (`theme_controller.dart`, `SharedPreferences`).
- La bascule est **animée** : `AppTokens.lerp` interpole chaque token, donc le
  passage clair ↔ sombre fond au lieu de claquer.

---

## 4. Composants

`import 'package:eventhub/core/widgets/design_system.dart';` donne accès à
tout le vocabulaire.

### Structure
| Composant | Rôle |
|---|---|
| `AppScaffold` | Chrome standard : fond ambiant, style des barres système, largeur de contenu bornée à 560 px sur grand écran |
| `AuroraBackground` | Deux halos radiaux très doux sur la couleur de fond — de la profondeur sans image ni shader |
| `FrostedBar` | Barre floutée collée en bas (actions persistantes) |
| `AppSurface` | **La** primitive conteneur. Cartes, tuiles, panneaux, lignes de liste |
| `GlassPanel` | Panneau translucide flouté. Réservé à ce qui doit laisser voir dessous — le flou coûte cher |
| `AppNavBar` | Barre de navigation flottante : pastille dégradée sur l'onglet actif, label uniquement sur l'actif, retour haptique |

### Contenu
| Composant | Rôle |
|---|---|
| `SectionHeader` / `SectionLabel` / `ScreenHeader` | Hiérarchie de titres |
| `AppBadge` / `LiveBadge` / `DateBadge` / `CountBadge` | Statuts, dates, compteurs |
| `AppAvatar` / `AvatarStack` | Identité — dégradé **déterministe** dérivé du nom |
| `CapacityMeter` | Jauge de remplissage ; la couleur est *dérivée* de la rareté, jamais passée en paramètre |
| `StatTile` | KPI (dashboard organisateur) |
| `SuccessHero` | Anneau concentrique des écrans de succès |
| `Skeleton` / `SkeletonParagraph` | Placeholders animés, respectent « réduire les animations » |
| `EventImage` | Visuel d'événement avec **repli dégradé déterministe** — un événement sans photo reste présentable |

### Interaction
| Composant | Rôle |
|---|---|
| `AppButton` | 5 variantes (`primary`, `secondary`, `tonal`, `ghost`, `danger`), 3 tailles, état de chargement qui bloque le double-envoi |
| `IconActionButton` / `OverlayIconButton` / `GradientFab` | Actions iconiques |
| `LabeledField` / `AppSearchField` / `PickerField` | Formulaires |
| `showAppSheet` / `AppSheet` / `showConfirmSheet` | Feuilles modales |
| `EmptyStateView` / `ErrorStateView` / `LoadingStateView` | États de rien-à-afficher |

---

## 5. Décisions notables (et leur raison)

**Le label du bouton de navigation n'apparaît que sur l'onglet actif.**
Il apparaît là où l'œil se trouve déjà, et la barre reste lisible à quatre
destinations. Un seul conteneur animé se déplace, ce qui se lit comme *un
objet qui bouge* plutôt que quatre objets qui clignotent.

**La barre de navigation flotte au lieu de coller au bord.**
Le contenu défile visiblement dessous : l'application paraît stratifiée.

**Le libellé de formulaire est au-dessus du champ, jamais dedans.**
Un label-placeholder disparaît dès la première frappe — l'utilisateur perd la
question au moment où il y répond. C'est une cause classique d'abandon.

**La contrainte est annoncée avant l'erreur.**
« 5 Mo maximum », « au moins 6 caractères » : `LabeledField.hint` existe pour
ça. La validation devient l'exception, pas le parcours normal.

**Dans une feuille de confirmation destructive, l'action dangereuse est
au-dessus de « Annuler ».**
L'option sûre est la plus proche du pouce.

**Les états vides ont une action.**
Un état vide sans issue est un cul-de-sac. Chacun propose un bouton qui en
sort (« Effacer les filtres », « Explorer les événements »).

**Un événement sans image n'est pas une erreur.**
`EventImage` génère un dégradé déterministe à partir de l'id : le fil reste
soigné, et le même événement garde ses couleurs partout où il apparaît.

**Le fil d'accueil est éditorialisé, pas chronologique.**
Une liste chronologique est ce qu'une base de données renvoie ; des rails
nommés (« À la une », « Ça se remplit vite », « Cette semaine ») sont ce qu'un
produit propose. Dès qu'un filtre est actif, les rails s'effacent au profit
d'une liste unique : l'utilisateur a exprimé une intention, l'éditorialiser
devient une gêne.

**L'échelle de texte est bornée à [0,85 – 1,35].**
Au-delà, les cartes denses du fil se disloquent. Brider est un compromis
assumé ; l'alternative est d'ignorer complètement le réglage d'accessibilité.

---

## 6. Ajouter un composant

1. Le nommer par son **rôle**, pas par son apparence (`CapacityMeter`, pas
   `OrangeBar`).
2. N'accepter **aucune couleur brute** en paramètre : un `AppTone`, ou rien.
3. Le rendre lisible dans les deux thèmes — le vérifier, pas le supposer.
4. Respecter les échelles d'espacement et de rayon.
5. L'exporter depuis `design_system.dart`.
6. Documenter la décision non évidente en commentaire — le *pourquoi*, jamais
   le *quoi*.
