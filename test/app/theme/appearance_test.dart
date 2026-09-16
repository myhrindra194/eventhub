import 'package:eventhub/app/theme/theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Personnalisation de l'apparence : ce qui doit tenir, quoi qu'on ajoute
/// comme modèle ou police plus tard.
///
///  1. **Iris ne change rien** — c'est l'apparence d'origine, celle que
///     valident les tests de rendu ;
///  2. **un modèle ne touche que la marque** — les couleurs d'état portent un
///     sens (« complet », « annulé ») et ne doivent jamais varier ;
///  3. **les choix survivent au redémarrage**.
void main() {
  group('ColorTemplate', () {
    test('Iris rend les tokens d’origine, en clair comme en sombre', () {
      expect(ColorTemplate.iris.apply(AppTokens.light), same(AppTokens.light));
      expect(ColorTemplate.iris.apply(AppTokens.dark), same(AppTokens.dark));
    });

    test('un modèle change la marque et laisse les états intacts', () {
      for (final template in ColorTemplate.values.skip(1)) {
        for (final base in [AppTokens.light, AppTokens.dark]) {
          final tokens = template.apply(base);
          expect(tokens.brand, isNot(base.brand), reason: template.name);
          expect(tokens.danger.fg, base.danger.fg, reason: template.name);
          expect(tokens.success.fg, base.success.fg, reason: template.name);
          expect(tokens.accent, base.accent, reason: template.name);
          expect(tokens.canvas, base.canvas, reason: template.name);
        }
      }
    });

    test('le sombre prend une teinte plus lumineuse que le clair', () {
      for (final template in ColorTemplate.values) {
        expect(
          template.dark.$1.computeLuminance(),
          greaterThan(template.light.$1.computeLuminance()),
          reason: template.name,
        );
      }
    });
  });

  group('AppearanceController', () {
    test('restaure le modèle et la police enregistrés', () async {
      SharedPreferences.setMockInitialValues({
        'appearance_template_v1': 'forest',
        'appearance_font_v1': 'rounded',
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(appearanceControllerProvider), const Appearance());
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(
        container.read(appearanceControllerProvider),
        const Appearance(
          template: ColorTemplate.forest,
          font: FontChoice.rounded,
        ),
      );
    });

    test('enregistre un nouveau choix', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(appearanceControllerProvider.notifier);

      await notifier.setTemplate(ColorTemplate.coral);
      await notifier.setFont(FontChoice.editorial);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('appearance_template_v1'), 'coral');
      expect(prefs.getString('appearance_font_v1'), 'editorial');
      expect(
        container.read(appearanceControllerProvider).template,
        ColorTemplate.coral,
      );
    });
  });
}
