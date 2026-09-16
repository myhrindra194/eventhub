import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Système typographique.
///
/// Deux familles, un rôle chacune — le classique duo « éditorial » :
///  * **Plus Jakarta Sans** pour display/headline/title. Géométrique avec
///    des détails humanistes ; en grandes tailles et à tracking serré, elle
///    donne une voix au produit au lieu d’une app Material par défaut.
///  * **Inter** pour le corps, les labels et toutes les chaînes d’UI
///    denses. Elle a été dessinée pour l’écran : elle reste lisible à
///    12–14 px, là où une display se désagrégerait.
///
/// Les tailles suivent une échelle modulaire d’environ 1.2, et chaque
/// palier au-dessus de 20 px reçoit un tracking négatif : un grand texte au
/// tracking par défaut paraît lâche.
abstract final class AppTypography {
  static TextTheme textTheme({
    required Color primary,
    required Color secondary,
  }) {
    final display = GoogleFonts.plusJakartaSansTextTheme();
    final body = GoogleFonts.interTextTheme();

    TextStyle d(TextStyle? base) => (base ?? const TextStyle()).copyWith(
      color: primary,
      fontFamilyFallback: const ['Inter', 'Roboto'],
    );
    TextStyle b(TextStyle? base) => (base ?? const TextStyle()).copyWith(
      color: primary,
      fontFamilyFallback: const ['Roboto'],
    );

    return TextTheme(
      // -------------------------------------------------------- display
      displayLarge: d(display.displayLarge).copyWith(
        fontSize: 44,
        height: 1.05,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.4,
      ),
      displayMedium: d(display.displayMedium).copyWith(
        fontSize: 36,
        height: 1.08,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.1,
      ),
      displaySmall: d(display.displaySmall).copyWith(
        fontSize: 30,
        height: 1.12,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
      ),
      // ------------------------------------------------------- headline
      headlineLarge: d(display.headlineLarge).copyWith(
        fontSize: 26,
        height: 1.18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
      ),
      headlineMedium: d(display.headlineMedium).copyWith(
        fontSize: 22,
        height: 1.22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
      headlineSmall: d(display.headlineSmall).copyWith(
        fontSize: 19,
        height: 1.26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
      ),
      // ---------------------------------------------------------- title
      titleLarge: d(display.titleLarge).copyWith(
        fontSize: 17,
        height: 1.3,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      titleMedium: b(body.titleMedium).copyWith(
        fontSize: 15,
        height: 1.35,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
      ),
      titleSmall: b(
        body.titleSmall,
      ).copyWith(fontSize: 13.5, height: 1.35, fontWeight: FontWeight.w600),
      // ----------------------------------------------------------- body
      bodyLarge: b(body.bodyLarge).copyWith(fontSize: 16, height: 1.55),
      bodyMedium: b(
        body.bodyMedium,
      ).copyWith(fontSize: 14, height: 1.5, color: secondary),
      bodySmall: b(
        body.bodySmall,
      ).copyWith(fontSize: 12.5, height: 1.45, color: secondary),
      // ---------------------------------------------------------- label
      labelLarge: b(
        body.labelLarge,
      ).copyWith(fontSize: 13, height: 1.2, fontWeight: FontWeight.w600),
      labelMedium: b(body.labelMedium).copyWith(
        fontSize: 11,
        height: 1.2,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.9,
        color: secondary,
      ),
      labelSmall: b(body.labelSmall).copyWith(
        fontSize: 10,
        height: 1.2,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
        color: secondary,
      ),
    );
  }

  /// Chiffres tabulaires — pour les compteurs, les capacités et les comptes
  /// à rebours qui ne doivent pas tressauter quand les chiffres changent.
  static const tabular = TextStyle(
    fontFeatures: [FontFeature.tabularFigures()],
  );
}
