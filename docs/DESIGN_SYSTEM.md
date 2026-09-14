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

**`button = input = 6 px`** — la valeur de référence du produit.

Tout ce que l'utilisateur **touche ou remplit** a le même bord net de 6 px :
boutons, champs, puces de filtre, bouton de fermeture. Les **feuilles modales**
aussi (`AppRadius.brModalSheet`, coins supérieurs à 6 px), ainsi que tout ce
qu'elles contiennent, et les nouveaux blocs (billet, statistiques, alertes).
Un grand rayon sur un bouton est le signe le plus sûr d'un gabarit par
défaut ; l'identité du produit tient à sa photographie et à sa typographie, pas
à des coins mous.

Échelle secondaire, pour les surfaces héritées et les imbrications :
`xs 8 · sm 12 · md 16 · lg 20 · xl 24 · xxl 28 · xxxl 34 · pill 999`.
`brSheet` (34 px) reste réservé au bloc de contenu qui chevauche l'image de la
fiche événement — ce n'est pas une modale.

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
| `showAppSheet` / `AppSheet` / `showConfirmSheet` | Feuilles modales : coins à 6 px, **sans poignée**, en-tête / contenu / actions séparés par des filets |
| `SheetCloseButton` | ✕ carré à 6 px, sortie explicite de toute feuille (remplace la poignée) |
| `FieldGroup` / `FieldRow` / `PasswordFieldRow` | Formulaires groupés (connexion, profil, mot de passe) |
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

**Les feuilles modales n'ont pas de poignée.**
La barre de préhension est une convention iOS qui se lit comme du décor de
gabarit. Chaque feuille porte un bouton ✕ explicite ; le glisser vers le bas et
le tap sur le voile ferment toujours. La feuille de confirmation est alignée à
gauche, comme une lettre, plutôt que centrée comme une pop-up.

**Le billet est toujours noir sur blanc, quel que soit le thème.**
Les scanners lisent mal un QR code inversé. Le code court sous le QR
(`EH-XXXX-XXXX`, sans `0/O/1/I/L`) sert quand le scan échoue : il se lit à voix
haute sans ambiguïté.

**Les graphiques suivent une règle, pas un goût.**
L'histogramme des statistiques n'a qu'une série, donc une seule teinte (la
marque) : colonnes ≤ 24 px, bout arrondi à 4 px et base carrée, écart de 2 px,
valeurs affichées seulement sur le pic et sur le jour sélectionné, et une vue
**tableau** qui porte exactement les mêmes valeurs. Un seul chiffre-héros par
écran, en chiffres proportionnels ; les chiffres tabulaires sont réservés aux
colonnes qui doivent s'aligner.

**Le verdict d'entrée est une bande pleine, pas une carte.**
Au contrôle, le regard du bénévole passe de la file à l'écran une demi-seconde :
un aplat vert, ambre ou rouge sur toute la largeur, un mot, le nom du titulaire.
Le retour haptique diffère (léger pour « entrez », fort pour un refus), ce qui
permet de scanner sans regarder.

**Refuser est aussi simple qu'accepter.**
La feuille de consentement présente « Accepter » et « Refuser » avec la même
largeur et la même hiérarchie de ligne ; un consentement plus facile à donner
qu'à refuser n'en est pas un.

**Un favori ne se confirme pas par un toast.**
Le cœur qui se remplit est la confirmation ; un message en plus répéterait
l'information à chaque geste.

**Les avis se lisent par la forme, puis par le nombre.**
Moyenne en grand, barres de répartition d'une seule teinte, compte imprimé à
côté de chaque barre : les barres donnent l'allure, les chiffres portent la
valeur.

**Le bandeau hors ligne n'empêche rien.**
Il explique pourquoi les données ne se rafraîchissent pas ; le cache permet de
continuer à consulter ses billets.

**Un profil organisateur se lit comme un en-tête de lettre.**
Identité et présentation alignées à gauche, puis trois faits dans une rangée
à filets (événements, abonnés, note) — chiffre en grand, unité en petit
dessous — puis l'unique action. Pas de bannière, pas d'avatar centré sur un
dégradé : ce qui fait confiance, ce sont les chiffres et les dates.

**Suivre et Abonné ne sont pas le même bouton.**
L'état « à faire » est un aplat de marque, l'état « fait » un bouton
secondaire avec une coche. Changer seulement le libellé d'un bouton plein
ferait croire qu'il reste une action à accomplir.

**La preuve sociale est une phrase, pas un badge.**
« Soa, Hery R. et 40 autres y vont » : deux prénoms puis un nombre, les
visages à gauche. Le nombre vient de la jauge, donc il est juste avant même
que les noms n'arrivent ; la ligne disparaît quand personne ne s'est inscrit.

**Signaler se fait dans une liste fermée, en rouge retenu.**
Chaque motif a sa ligne d'explication ; la sélection teinte la ligne et
épaissit l'anneau plutôt que d'ajouter une coche. Le bouton d'envoi reste
désactivé tant qu'aucun motif n'est choisi, et la feuille dit d'emblée que le
signalement est anonyme.

**La page web publique parle la même langue que l'app.**
Filets, rayon de 6 px, une seule couleur d'accent, clair et sombre selon le
système, aucune image de remplissage : la table « Date · Heure · Lieu ·
Organisé par » reprend la grille du billet.

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
