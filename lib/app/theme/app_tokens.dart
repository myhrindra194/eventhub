import 'package:eventhub/app/theme/app_palette.dart';
import 'package:flutter/material.dart';

/// Paire de couleurs sémantiques utilisée par les surfaces de statut
/// (succès, avertissement, danger, info, marque). [fg] est lisible sur [bg],
/// et [bg] est lisible sur le fond de l’écran — c’est cet invariant qui
/// permet de poser le même composant pilule n’importe où sans refaire un
/// audit de contraste.
@immutable
class ToneColors {
  const ToneColors({
    required this.fg,
    required this.bg,
    required this.border,
    required this.solid,
    required this.onSolid,
  });

  /// Couleur du texte et des icônes sur un fond teinté.
  final Color fg;

  /// La teinte elle-même (faible alpha ou faible chroma).
  final Color bg;

  /// Filet pour les variantes en contour.
  final Color border;

  /// Aplat pleinement saturé, pour la variante la plus sonore.
  final Color solid;

  /// Couleur du texte et des icônes sur [solid].
  final Color onSolid;

  static ToneColors lerp(ToneColors a, ToneColors b, double t) => ToneColors(
    fg: Color.lerp(a.fg, b.fg, t)!,
    bg: Color.lerp(a.bg, b.bg, t)!,
    border: Color.lerp(a.border, b.border, t)!,
    solid: Color.lerp(a.solid, b.solid, t)!,
    onSolid: Color.lerp(a.onSolid, b.onSolid, t)!,
  );
}

/// Les jetons de design d'EventHub, attachés à `ThemeData.extensions`.
///
/// Il n'y a **aucune ombre** dans ce jeu de jetons, et c'est une décision, pas
/// un oubli : la profondeur du produit vient des filets, des fonds creusés et
/// du contraste. Une ombre portée est le marqueur le plus immédiat d'un
/// gabarit par défaut, et sur un fond sombre elle se lit comme une salissure
/// plutôt que comme une élévation. Deux plans se distinguent donc par leur
/// couleur de surface et leur bordure — jamais par un flou noir.
///
/// Les widgets lisent `context.tokens` au lieu d'importer une palette :
/// échanger l'instance claire et l'instance sombre est donc la *seule* chose
/// nécessaire pour repeindre toute l'application, et `ThemeExtension.lerp`
/// fait que la bascule clair/sombre s'anime au lieu de sauter.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.brightness,
    required this.canvas,
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceSunken,
    required this.surfaceOverlay,
    required this.glass,
    required this.scrim,
    required this.borderSubtle,
    required this.border,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textOnBrand,
    required this.brand,
    required this.brandSoft,
    required this.brandStrong,
    required this.accent,
    required this.accentSoft,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.neutralTone,
    required this.brandGradient,
    required this.accentGradient,
    required this.heroScrim,
    required this.bloomPrimary,
    required this.bloomSecondary,
    required this.skeletonBase,
    required this.skeletonHighlight,
  });

  final Brightness brightness;

  // ---------------------------------------------------------- plans de fond
  /// Le fond de la page.
  final Color canvas;

  /// Couleur par défaut des cartes et panneaux, à un pas du canvas.
  final Color surface;

  /// Une surface qui doit paraître *plus proche* de l’utilisateur (barres
  /// collantes, menus).
  final Color surfaceRaised;

  /// Un creux : champs, piste d’une barre de progression, placeholders.
  final Color surfaceSunken;

  /// Sheets et dialogues, qui se posent au-dessus d’un scrim.
  final Color surfaceOverlay;

  /// Remplissage translucide pour les éléments dépolis (floutés).
  final Color glass;

  /// Assombrissement derrière les modales.
  final Color scrim;

  // ---------------------------------------------------------------- filets
  final Color borderSubtle;
  final Color border;
  final Color borderStrong;

  // ----------------------------------------------------------------- texte
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textOnBrand;

  // ---------------------------------------------------------------- marque
  final Color brand;
  final Color brandSoft;
  final Color brandStrong;
  final Color accent;
  final Color accentSoft;

  // ------------------------------------------------------------ sémantique
  final ToneColors success;
  final ToneColors warning;
  final ToneColors danger;
  final ToneColors info;
  final ToneColors neutralTone;

  // ----------------------------------------------------------- décorations
  final LinearGradient brandGradient;
  final LinearGradient accentGradient;

  /// Scrim vertical posé sur les photos hero pour que le texte blanc reste
  /// lisible quelle que soit l’image.
  final LinearGradient heroScrim;

  final Color bloomPrimary;
  final Color bloomSecondary;

  final Color skeletonBase;
  final Color skeletonHighlight;

  bool get isDark => brightness == Brightness.dark;

  /// Ton correspondant au taux de remplissage d’un événement — utilisé par
  /// les jauges de capacité pour que la sémantique de couleur (« presque
  /// complet ») soit décidée une seule fois.
  ToneColors seatTone({required int available, required int capacity}) {
    if (available <= 0) return danger;
    if (capacity > 0 && available <= 3) return warning;
    return success;
  }

  @override
  AppTokens copyWith({
    Brightness? brightness,
    Color? canvas,
    Color? surface,
    Color? surfaceRaised,
    Color? surfaceSunken,
    Color? surfaceOverlay,
    Color? glass,
    Color? scrim,
    Color? borderSubtle,
    Color? border,
    Color? borderStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textOnBrand,
    Color? brand,
    Color? brandSoft,
    Color? brandStrong,
    Color? accent,
    Color? accentSoft,
    ToneColors? success,
    ToneColors? warning,
    ToneColors? danger,
    ToneColors? info,
    ToneColors? neutralTone,
    LinearGradient? brandGradient,
    LinearGradient? accentGradient,
    LinearGradient? heroScrim,
    Color? bloomPrimary,
    Color? bloomSecondary,
    Color? skeletonBase,
    Color? skeletonHighlight,
  }) {
    return AppTokens(
      brightness: brightness ?? this.brightness,
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      surfaceSunken: surfaceSunken ?? this.surfaceSunken,
      surfaceOverlay: surfaceOverlay ?? this.surfaceOverlay,
      glass: glass ?? this.glass,
      scrim: scrim ?? this.scrim,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textOnBrand: textOnBrand ?? this.textOnBrand,
      brand: brand ?? this.brand,
      brandSoft: brandSoft ?? this.brandSoft,
      brandStrong: brandStrong ?? this.brandStrong,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      info: info ?? this.info,
      neutralTone: neutralTone ?? this.neutralTone,
      brandGradient: brandGradient ?? this.brandGradient,
      accentGradient: accentGradient ?? this.accentGradient,
      heroScrim: heroScrim ?? this.heroScrim,
      bloomPrimary: bloomPrimary ?? this.bloomPrimary,
      bloomSecondary: bloomSecondary ?? this.bloomSecondary,
      skeletonBase: skeletonBase ?? this.skeletonBase,
      skeletonHighlight: skeletonHighlight ?? this.skeletonHighlight,
    );
  }

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    return AppTokens(
      brightness: t < 0.5 ? brightness : other.brightness,
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      surfaceSunken: Color.lerp(surfaceSunken, other.surfaceSunken, t)!,
      surfaceOverlay: Color.lerp(surfaceOverlay, other.surfaceOverlay, t)!,
      glass: Color.lerp(glass, other.glass, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      textOnBrand: Color.lerp(textOnBrand, other.textOnBrand, t)!,
      brand: Color.lerp(brand, other.brand, t)!,
      brandSoft: Color.lerp(brandSoft, other.brandSoft, t)!,
      brandStrong: Color.lerp(brandStrong, other.brandStrong, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      success: ToneColors.lerp(success, other.success, t),
      warning: ToneColors.lerp(warning, other.warning, t),
      danger: ToneColors.lerp(danger, other.danger, t),
      info: ToneColors.lerp(info, other.info, t),
      neutralTone: ToneColors.lerp(neutralTone, other.neutralTone, t),
      brandGradient: LinearGradient.lerp(
        brandGradient,
        other.brandGradient,
        t,
      )!,
      accentGradient: LinearGradient.lerp(
        accentGradient,
        other.accentGradient,
        t,
      )!,
      heroScrim: LinearGradient.lerp(heroScrim, other.heroScrim, t)!,
      bloomPrimary: Color.lerp(bloomPrimary, other.bloomPrimary, t)!,
      bloomSecondary: Color.lerp(bloomSecondary, other.bloomSecondary, t)!,
      skeletonBase: Color.lerp(skeletonBase, other.skeletonBase, t)!,
      skeletonHighlight: Color.lerp(
        skeletonHighlight,
        other.skeletonHighlight,
        t,
      )!,
    );
  }

  // ==========================================================================
  //  Clair
  // ==========================================================================
  static const light = AppTokens(
    brightness: Brightness.light,
    canvas: AppPalette.neutral50,
    surface: AppPalette.neutral0,
    surfaceRaised: AppPalette.neutral0,
    surfaceSunken: AppPalette.neutral100,
    surfaceOverlay: AppPalette.neutral0,
    glass: Color(0xE6FFFFFF),
    scrim: Color(0x66101420),
    borderSubtle: AppPalette.neutral100,
    border: AppPalette.neutral200,
    borderStrong: AppPalette.neutral300,
    textPrimary: AppPalette.neutral900,
    textSecondary: AppPalette.neutral600,
    textTertiary: AppPalette.neutral400,
    textOnBrand: AppPalette.neutral0,
    brand: AppPalette.iris600,
    brandSoft: Color(0x145A4EE0),
    brandStrong: AppPalette.iris700,
    accent: AppPalette.ember600,
    accentSoft: Color(0x1AF97316),
    success: ToneColors(
      fg: AppPalette.mint600,
      bg: Color(0x1A10B981),
      border: Color(0x3310B981),
      solid: AppPalette.mint600,
      onSolid: AppPalette.neutral0,
    ),
    warning: ToneColors(
      fg: AppPalette.amber600,
      bg: Color(0x1FF59E0B),
      border: Color(0x38F59E0B),
      solid: AppPalette.amber500,
      onSolid: AppPalette.neutral900,
    ),
    danger: ToneColors(
      fg: AppPalette.rose600,
      bg: Color(0x1AF43F5E),
      border: Color(0x33F43F5E),
      solid: AppPalette.rose600,
      onSolid: AppPalette.neutral0,
    ),
    info: ToneColors(
      fg: AppPalette.sky600,
      bg: Color(0x1A0EA5E9),
      border: Color(0x330EA5E9),
      solid: AppPalette.sky600,
      onSolid: AppPalette.neutral0,
    ),
    neutralTone: ToneColors(
      fg: AppPalette.neutral600,
      bg: AppPalette.neutral100,
      border: AppPalette.neutral200,
      solid: AppPalette.neutral700,
      onSolid: AppPalette.neutral0,
    ),
    brandGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppPalette.iris500, AppPalette.iris700],
    ),
    accentGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppPalette.ember400, AppPalette.ember600],
    ),
    heroScrim: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0x00000000), Color(0x4D000000), Color(0xD9101420)],
      stops: [0.3, 0.62, 1],
    ),
    bloomPrimary: Color(0x266A63E6),
    bloomSecondary: Color(0x1FF97316),
    skeletonBase: AppPalette.neutral100,
    skeletonHighlight: AppPalette.neutral50,
  );

  // ==========================================================================
  //  Sombre
  // ==========================================================================
  static const dark = AppTokens(
    brightness: Brightness.dark,
    canvas: AppPalette.neutral1000,
    surface: Color(0xFF141925),
    surfaceRaised: Color(0xFF1B2130),
    surfaceSunken: Color(0xFF0F131C),
    surfaceOverlay: Color(0xFF181E2B),
    glass: Color(0xCC141925),
    scrim: Color(0x99050710),
    borderSubtle: Color(0x0FFFFFFF),
    border: Color(0x1AFFFFFF),
    borderStrong: Color(0x2EFFFFFF),
    textPrimary: Color(0xFFF3F5FA),
    textSecondary: Color(0xFF9BA5BA),
    textTertiary: Color(0xFF6B7488),
    textOnBrand: AppPalette.neutral0,
    brand: AppPalette.iris400,
    brandSoft: Color(0x2E867FF0),
    brandStrong: AppPalette.iris300,
    accent: AppPalette.ember400,
    accentSoft: Color(0x2EFF9A62),
    success: ToneColors(
      fg: AppPalette.mint400,
      bg: Color(0x2634D399),
      border: Color(0x4034D399),
      solid: AppPalette.mint500,
      onSolid: Color(0xFF04231A),
    ),
    warning: ToneColors(
      fg: AppPalette.amber400,
      bg: Color(0x26FBBF24),
      border: Color(0x40FBBF24),
      solid: AppPalette.amber400,
      onSolid: Color(0xFF2A1C02),
    ),
    danger: ToneColors(
      fg: AppPalette.rose400,
      bg: Color(0x26FB7185),
      border: Color(0x40FB7185),
      solid: AppPalette.rose500,
      onSolid: AppPalette.neutral0,
    ),
    info: ToneColors(
      fg: AppPalette.sky400,
      bg: Color(0x2638BDF8),
      border: Color(0x4038BDF8),
      solid: AppPalette.sky500,
      onSolid: Color(0xFF04202E),
    ),
    neutralTone: ToneColors(
      fg: Color(0xFF9BA5BA),
      bg: Color(0x14FFFFFF),
      border: Color(0x1AFFFFFF),
      solid: Color(0xFF394154),
      onSolid: Color(0xFFF3F5FA),
    ),
    brandGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppPalette.iris400, AppPalette.iris600],
    ),
    accentGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppPalette.ember400, AppPalette.ember600],
    ),
    heroScrim: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0x00000000), Color(0x66000000), Color(0xF2090C12)],
      stops: [0.3, 0.62, 1],
    ),
    bloomPrimary: Color(0x59564ED4),
    bloomSecondary: Color(0x2EF97316),
    skeletonBase: Color(0xFF1B2130),
    skeletonHighlight: Color(0xFF262E40),
  );
}

/// Intention sémantique d’une surface de statut. Les composants prennent un
/// [AppTone] et le résolvent contre les tokens : un appelant ne choisit
/// jamais une couleur brute.
enum AppTone { brand, accent, success, warning, danger, info, neutral }

extension AppToneResolver on AppTokens {
  ToneColors resolve(AppTone tone) => switch (tone) {
    AppTone.brand => ToneColors(
      fg: brand,
      bg: brandSoft,
      border: brand.withValues(alpha: 0.32),
      solid: brand,
      onSolid: textOnBrand,
    ),
    AppTone.accent => ToneColors(
      fg: accent,
      bg: accentSoft,
      border: accent.withValues(alpha: 0.32),
      solid: accent,
      onSolid: textOnBrand,
    ),
    AppTone.success => success,
    AppTone.warning => warning,
    AppTone.danger => danger,
    AppTone.info => info,
    AppTone.neutral => neutralTone,
  };
}

/// Accès ergonomique : `context.tokens.surface`.
extension AppTokensX on BuildContext {
  AppTokens get tokens =>
      Theme.of(this).extension<AppTokens>() ??
      (Theme.of(this).brightness == Brightness.dark
          ? AppTokens.dark
          : AppTokens.light);
}
