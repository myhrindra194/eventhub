import 'package:eventhub/app/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'appearance.g.dart';

/// Un modèle de couleurs : la teinte de marque de toute l'interface.
///
/// **Ce qu'un modèle change, et ce qu'il ne touche pas.** Il remplace la
/// marque — boutons principaux, sélection, liens, onglet actif, dégradés et
/// halos de fond —, et rien d'autre. Les neutres, les couleurs d'état
/// (succès, alerte, erreur) et l'accent orange des étincelles restent
/// identiques : ce sont eux qui portent le sens (« complet », « annulé ») et
/// l'identité EventHub. Changer de modèle personnalise l'app sans la rendre
/// méconnaissable ni rendre un état ambigu.
///
/// Chaque modèle fournit deux jeux — clair et sombre — parce qu'une même
/// teinte ne se lit pas pareil sur les deux fonds : le sombre prend un palier
/// plus lumineux pour garder le contraste du texte et des bordures.
enum ColorTemplate {
  iris(
    label: 'Iris',
    light: (Color(0xFF564ED4), Color(0xFF463FB3), Color(0xFF6A63E6)),
    dark: (Color(0xFF867FF0), Color(0xFFA5A2F6), Color(0xFF564ED4)),
  ),
  ocean(
    label: 'Océan',
    light: (Color(0xFF0369A1), Color(0xFF075985), Color(0xFF0284C7)),
    dark: (Color(0xFF38BDF8), Color(0xFF7DD3FC), Color(0xFF0284C7)),
  ),
  forest(
    label: 'Forêt',
    light: (Color(0xFF047857), Color(0xFF065F46), Color(0xFF059669)),
    dark: (Color(0xFF34D399), Color(0xFF6EE7B7), Color(0xFF059669)),
  ),
  coral(
    label: 'Corail',
    light: (Color(0xFFE11D48), Color(0xFFBE123C), Color(0xFFF43F5E)),
    dark: (Color(0xFFFB7185), Color(0xFFFDA4AF), Color(0xFFE11D48)),
  ),
  graphite(
    label: 'Graphite',
    light: (Color(0xFF334155), Color(0xFF1E293B), Color(0xFF475569)),
    dark: (Color(0xFF94A3B8), Color(0xFFCBD5E1), Color(0xFF475569)),
  );

  const ColorTemplate({
    required this.label,
    required this.light,
    required this.dark,
  });

  final String label;

  /// (marque, marque appuyée, départ du dégradé) sur fond clair.
  final (Color, Color, Color) light;

  /// Idem sur fond sombre.
  final (Color, Color, Color) dark;

  /// La pastille montrée dans le sélecteur.
  Color get swatch => light.$1;

  /// Applique le modèle à un jeu de tokens. Iris est le jeu d'origine : il
  /// rend les tokens tels quels, pour que l'apparence par défaut reste
  /// strictement celle que les tests de rendu valident.
  AppTokens apply(AppTokens base) {
    if (this == ColorTemplate.iris) return base;
    final (brand, strong, gradientStart) = base.isDark ? dark : light;
    return base.copyWith(
      brand: brand,
      brandStrong: strong,
      brandSoft: brand.withValues(alpha: base.isDark ? 0.18 : 0.08),
      brandGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: base.isDark ? [brand, gradientStart] : [gradientStart, strong],
      ),
      bloomPrimary: brand.withValues(alpha: base.isDark ? 0.14 : 0.12),
    );
  }
}

/// Une police de l'interface : une famille pour les titres, une pour le texte.
///
/// Chaque choix est un **couple** et non une seule famille, parce que les
/// titres et le texte courant n'ont pas les mêmes besoins : une police de
/// titre peut avoir du caractère aux grandes tailles, le texte doit rester
/// lisible à 12 px. Les couples proposés ont été retenus pour rester nets
/// sur écran et couvrir tous les accents du français.
enum FontChoice {
  modern(label: 'Moderne', sample: 'Plus Jakarta Sans · Inter'),
  neutral(label: 'Sobre', sample: 'Inter'),
  geometric(label: 'Géométrique', sample: 'Poppins · DM Sans'),
  rounded(label: 'Arrondie', sample: 'Nunito'),
  editorial(label: 'Éditoriale', sample: 'Fraunces · Source Sans 3');

  const FontChoice({required this.label, required this.sample});

  final String label;

  /// Les familles utilisées, montrées sous le libellé.
  final String sample;

  TextTheme get display => switch (this) {
    FontChoice.modern => GoogleFonts.plusJakartaSansTextTheme(),
    FontChoice.neutral => GoogleFonts.interTextTheme(),
    FontChoice.geometric => GoogleFonts.poppinsTextTheme(),
    FontChoice.rounded => GoogleFonts.nunitoTextTheme(),
    FontChoice.editorial => GoogleFonts.frauncesTextTheme(),
  };

  TextTheme get body => switch (this) {
    FontChoice.modern || FontChoice.neutral => GoogleFonts.interTextTheme(),
    FontChoice.geometric => GoogleFonts.dmSansTextTheme(),
    FontChoice.rounded => GoogleFonts.nunitoTextTheme(),
    FontChoice.editorial => GoogleFonts.sourceSans3TextTheme(),
  };

  /// Style d'aperçu « Aa » dans la famille des titres.
  TextStyle preview(TextStyle base) => switch (this) {
    FontChoice.modern => GoogleFonts.plusJakartaSans(textStyle: base),
    FontChoice.neutral => GoogleFonts.inter(textStyle: base),
    FontChoice.geometric => GoogleFonts.poppins(textStyle: base),
    FontChoice.rounded => GoogleFonts.nunito(textStyle: base),
    FontChoice.editorial => GoogleFonts.fraunces(textStyle: base),
  };
}

/// Apparence personnalisée : modèle de couleurs et police, mémorisés sur
/// l'appareil. Le mode clair / sombre vit à part, dans
/// `ThemeModeController`, parce que son défaut suit le système.
@immutable
class Appearance {
  const Appearance({
    this.template = ColorTemplate.iris,
    this.font = FontChoice.modern,
  });

  final ColorTemplate template;
  final FontChoice font;

  Appearance copyWith({ColorTemplate? template, FontChoice? font}) =>
      Appearance(template: template ?? this.template, font: font ?? this.font);

  @override
  bool operator ==(Object other) =>
      other is Appearance && other.template == template && other.font == font;

  @override
  int get hashCode => Object.hash(template, font);
}

@Riverpod(keepAlive: true)
class AppearanceController extends _$AppearanceController {
  static const _templateKey = 'appearance_template_v1';
  static const _fontKey = 'appearance_font_v1';

  @override
  Appearance build() {
    // Même stratégie que le mode : la première image n'attend pas le disque,
    // l'apparence enregistrée s'applique dès qu'elle est lue (en fondu, grâce
    // à l'animation de thème de MaterialApp).
    Future.microtask(_restore);
    return const Appearance();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final template = ColorTemplate.values
        .where((t) => t.name == prefs.getString(_templateKey))
        .firstOrNull;
    final font = FontChoice.values
        .where((f) => f.name == prefs.getString(_fontKey))
        .firstOrNull;
    final restored = state.copyWith(template: template, font: font);
    if (restored != state) state = restored;
  }

  Future<void> setTemplate(ColorTemplate template) async {
    if (template == state.template) return;
    state = state.copyWith(template: template);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_templateKey, template.name);
  }

  Future<void> setFont(FontChoice font) async {
    if (font == state.font) return;
    state = state.copyWith(font: font);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fontKey, font.name);
  }
}
