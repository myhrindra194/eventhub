import 'package:eventhub/app/theme/app_palette.dart';
import 'package:flutter/material.dart';

/// A semantic colour pair used by status surfaces (success, warning,
/// danger, info, brand). [fg] is legible on [bg], and [bg] is legible on the
/// screen ground — that invariant is what lets the same pill component be
/// dropped anywhere without a contrast audit.
@immutable
class ToneColors {
  const ToneColors({
    required this.fg,
    required this.bg,
    required this.border,
    required this.solid,
    required this.onSolid,
  });

  /// Text/icon colour on a tinted background.
  final Color fg;

  /// The tint itself (low-alpha or low-chroma).
  final Color bg;

  /// Hairline for outlined variants.
  final Color border;

  /// Fully saturated fill, for the loudest variant.
  final Color solid;

  /// Text/icon colour on [solid].
  final Color onSolid;

  static ToneColors lerp(ToneColors a, ToneColors b, double t) => ToneColors(
    fg: Color.lerp(a.fg, b.fg, t)!,
    bg: Color.lerp(a.bg, b.bg, t)!,
    border: Color.lerp(a.border, b.border, t)!,
    solid: Color.lerp(a.solid, b.solid, t)!,
    onSolid: Color.lerp(a.onSolid, b.onSolid, t)!,
  );
}

/// Elevation as *shadow recipes* rather than a single `elevation: n`.
///
/// Material's numeric elevation bakes in a tint that reads badly on a dark
/// ground; a two-layer shadow (a tight contact shadow plus a wide ambient
/// one) is what actually makes a surface look lifted.
@immutable
class AppShadows {
  const AppShadows({
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
  });

  final List<BoxShadow> xs;
  final List<BoxShadow> sm;
  final List<BoxShadow> md;
  final List<BoxShadow> lg;
  final List<BoxShadow> xl;

  static AppShadows lerp(AppShadows a, AppShadows b, double t) => AppShadows(
    xs: BoxShadow.lerpList(a.xs, b.xs, t)!,
    sm: BoxShadow.lerpList(a.sm, b.sm, t)!,
    md: BoxShadow.lerpList(a.md, b.md, t)!,
    lg: BoxShadow.lerpList(a.lg, b.lg, t)!,
    xl: BoxShadow.lerpList(a.xl, b.xl, t)!,
  );
}

/// The EventHub design tokens, attached to `ThemeData.extensions`.
///
/// Widgets read `context.tokens` instead of importing a palette. Swapping
/// the light and the dark instance is therefore the *only* thing needed to
/// re-skin the entire application, and `ThemeExtension.lerp` makes the
/// light↔dark switch animate rather than snap.
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
    required this.shadows,
    required this.brandGradient,
    required this.accentGradient,
    required this.heroScrim,
    required this.bloomPrimary,
    required this.bloomSecondary,
    required this.skeletonBase,
    required this.skeletonHighlight,
  });

  final Brightness brightness;

  // ---------------------------------------------------------- ground layers
  /// The page background.
  final Color canvas;

  /// Default card / panel colour, one step off the canvas.
  final Color surface;

  /// A surface that must read as *closer* to the user (sticky bars, menus).
  final Color surfaceRaised;

  /// A recess: inputs, track of a progress bar, image placeholders.
  final Color surfaceSunken;

  /// Sheets and dialogs, which sit above a scrim.
  final Color surfaceOverlay;

  /// Translucent fill for frosted (blurred) elements.
  final Color glass;

  /// Dim behind modals.
  final Color scrim;

  // ----------------------------------------------------------------- lines
  final Color borderSubtle;
  final Color border;
  final Color borderStrong;

  // ------------------------------------------------------------------ text
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textOnBrand;

  // ----------------------------------------------------------------- brand
  final Color brand;
  final Color brandSoft;
  final Color brandStrong;
  final Color accent;
  final Color accentSoft;

  // ------------------------------------------------------------- semantics
  final ToneColors success;
  final ToneColors warning;
  final ToneColors danger;
  final ToneColors info;
  final ToneColors neutralTone;

  // ----------------------------------------------------------- decorations
  final AppShadows shadows;
  final LinearGradient brandGradient;
  final LinearGradient accentGradient;

  /// Vertical scrim laid over hero photography so white text stays legible
  /// whatever the image is.
  final LinearGradient heroScrim;

  final Color bloomPrimary;
  final Color bloomSecondary;

  final Color skeletonBase;
  final Color skeletonHighlight;

  bool get isDark => brightness == Brightness.dark;

  /// Tone matching an event fill rate — used by capacity meters so the
  /// colour semantics ("almost full") are decided once.
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
    AppShadows? shadows,
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
      shadows: shadows ?? this.shadows,
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
      shadows: AppShadows.lerp(shadows, other.shadows, t),
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
  //  Light
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
    shadows: AppShadows(
      xs: [
        BoxShadow(
          color: Color(0x0D0F1424),
          blurRadius: 2,
          offset: Offset(0, 1),
        ),
      ],
      sm: [
        BoxShadow(
          color: Color(0x140F1424),
          blurRadius: 6,
          offset: Offset(0, 2),
        ),
        BoxShadow(
          color: Color(0x0A0F1424),
          blurRadius: 2,
          offset: Offset(0, 1),
        ),
      ],
      md: [
        BoxShadow(
          color: Color(0x140F1424),
          blurRadius: 16,
          offset: Offset(0, 6),
        ),
        BoxShadow(
          color: Color(0x0F0F1424),
          blurRadius: 4,
          offset: Offset(0, 2),
        ),
      ],
      lg: [
        BoxShadow(
          color: Color(0x1A0F1424),
          blurRadius: 28,
          offset: Offset(0, 12),
        ),
        BoxShadow(
          color: Color(0x0F0F1424),
          blurRadius: 8,
          offset: Offset(0, 4),
        ),
      ],
      xl: [
        BoxShadow(
          color: Color(0x240F1424),
          blurRadius: 48,
          offset: Offset(0, 20),
        ),
        BoxShadow(
          color: Color(0x140F1424),
          blurRadius: 12,
          offset: Offset(0, 6),
        ),
      ],
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
  //  Dark
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
    shadows: AppShadows(
      xs: [
        BoxShadow(
          color: Color(0x59000000),
          blurRadius: 2,
          offset: Offset(0, 1),
        ),
      ],
      sm: [
        BoxShadow(
          color: Color(0x66000000),
          blurRadius: 8,
          offset: Offset(0, 3),
        ),
      ],
      md: [
        BoxShadow(
          color: Color(0x73000000),
          blurRadius: 20,
          offset: Offset(0, 8),
        ),
      ],
      lg: [
        BoxShadow(
          color: Color(0x80000000),
          blurRadius: 32,
          offset: Offset(0, 14),
        ),
      ],
      xl: [
        BoxShadow(
          color: Color(0x99000000),
          blurRadius: 56,
          offset: Offset(0, 24),
        ),
      ],
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

/// Semantic intent of a status surface. Components take an [AppTone] and
/// resolve it against the tokens, so a caller never picks a raw colour.
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

/// Ergonomic access: `context.tokens.surface`.
extension AppTokensX on BuildContext {
  AppTokens get tokens =>
      Theme.of(this).extension<AppTokens>() ??
      (Theme.of(this).brightness == Brightness.dark
          ? AppTokens.dark
          : AppTokens.light);
}
