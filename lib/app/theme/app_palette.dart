import 'package:flutter/painting.dart';

/// Raw colour ramps — the *only* place where a hexadecimal literal is
/// allowed in the application.
///
/// A ramp is never consumed directly by a widget: it is mapped to a
/// **semantic** token in `app_tokens.dart` (`surface`, `border`, `danger`…).
/// That indirection is what makes a light and a dark theme possible without
/// touching a single widget.
///
/// Ramps are numbered like Tailwind/Radix: 50 = lightest, 950 = darkest.
abstract final class AppPalette {
  // ------------------------------------------------------------- neutrals
  /// Slightly cool grey. Pure black/white are avoided: they vibrate against
  /// saturated content and make photography look flat.
  static const neutral0 = Color(0xFFFFFFFF);
  static const neutral25 = Color(0xFFFCFCFE);
  static const neutral50 = Color(0xFFF7F8FC);
  static const neutral100 = Color(0xFFEFF1F6);
  static const neutral200 = Color(0xFFE2E5EE);
  static const neutral300 = Color(0xFFCED3E0);
  static const neutral400 = Color(0xFFA4ACBF);
  static const neutral500 = Color(0xFF78829A);
  static const neutral600 = Color(0xFF5A6478);
  static const neutral700 = Color(0xFF3F4759);
  static const neutral800 = Color(0xFF272D3C);
  static const neutral900 = Color(0xFF181D29);
  static const neutral950 = Color(0xFF10141D);
  static const neutral1000 = Color(0xFF090C12);

  // ----------------------------------------------------------- brand: iris
  /// Indigo–violet. Confident without being neon; legible on both grounds.
  static const iris50 = Color(0xFFEEEEFE);
  static const iris100 = Color(0xFFE0DFFD);
  static const iris200 = Color(0xFFC5C3FA);
  static const iris300 = Color(0xFFA5A2F6);
  static const iris400 = Color(0xFF867FF0);
  static const iris500 = Color(0xFF6A63E6);
  static const iris600 = Color(0xFF564ED4);
  static const iris700 = Color(0xFF463FB3);
  static const iris800 = Color(0xFF383291);
  static const iris900 = Color(0xFF2C2872);

  // -------------------------------------------------------- accent: ember
  /// Warm counterweight to the brand hue. Used sparingly: highlights,
  /// "trending", the organizer's accent — never as a second primary.
  static const ember300 = Color(0xFFFFC49B);
  static const ember400 = Color(0xFFFF9A62);
  static const ember500 = Color(0xFFF97316);
  static const ember600 = Color(0xFFE25B08);

  // ----------------------------------------------------------- semantics
  static const mint300 = Color(0xFF6EE7B7);
  static const mint400 = Color(0xFF34D399);
  static const mint500 = Color(0xFF10B981);
  static const mint600 = Color(0xFF059669);

  static const amber300 = Color(0xFFFCD34D);
  static const amber400 = Color(0xFFFBBF24);
  static const amber500 = Color(0xFFF59E0B);
  static const amber600 = Color(0xFFD97706);

  static const rose300 = Color(0xFFFDA4AF);
  static const rose400 = Color(0xFFFB7185);
  static const rose500 = Color(0xFFF43F5E);
  static const rose600 = Color(0xFFE11D48);

  static const sky300 = Color(0xFF7DD3FC);
  static const sky400 = Color(0xFF38BDF8);
  static const sky500 = Color(0xFF0EA5E9);
  static const sky600 = Color(0xFF0284C7);

  // ------------------------------------------------------ category accents
  /// One hue per event category. They are deliberately spread around the
  /// wheel so a category is recognisable at chip size, and each has a
  /// light-mode and a dark-mode variant with comparable contrast.
  static const violet400 = Color(0xFFA78BFA);
  static const violet500 = Color(0xFF8B5CF6);
  static const fuchsia400 = Color(0xFFE879F9);
  static const fuchsia500 = Color(0xFFD946EF);
  static const teal400 = Color(0xFF2DD4BF);
  static const teal500 = Color(0xFF14B8A6);
  static const lime400 = Color(0xFFA3E635);
  static const lime500 = Color(0xFF84CC16);
}
