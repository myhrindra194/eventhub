import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/extensions/context_x.dart';
import 'package:eventhub/core/widgets/app_surface.dart';
import 'package:eventhub/core/widgets/theme_mode_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tout ce qui personnalise l'apparence, au même endroit : le mode (clair,
/// sombre, automatique), le modèle de couleurs et la police.
///
/// Présent dans Profil pour les deux espaces — participant et organisateur
/// partagent le même écran de profil —, et dans Paramètres. Chaque choix
/// s'applique à l'instant, dans toute l'app, et reste mémorisé sur
/// l'appareil. Rien à valider : un réglage d'apparence se juge en le voyant,
/// pas en lisant une confirmation.
class AppearanceSettings extends StatelessWidget {
  const AppearanceSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Caption('Mode'),
        SizedBox(height: AppSpacing.sm),
        ThemeModeSelector(),
        SizedBox(height: AppSpacing.xl),
        _Caption('Couleur'),
        SizedBox(height: AppSpacing.sm),
        _TemplateSelector(),
        SizedBox(height: AppSpacing.xl),
        _Caption('Police'),
        SizedBox(height: AppSpacing.sm),
        _FontSelector(),
      ],
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: AppSpacing.xs),
    child: Text(
      text,
      style: context.textTheme.titleSmall?.copyWith(
        color: context.tokens.textSecondary,
      ),
    ),
  );
}

/// Les modèles de couleurs, en pastilles carrées de 6 px de rayon — comme
/// tout le produit — avec leur nom dessous. La pastille montre la vraie
/// teinte de marque : on choisit ce que l'on voit.
class _TemplateSelector extends ConsumerWidget {
  const _TemplateSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final current = ref.watch(appearanceControllerProvider).template;

    return AppSurface(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          for (final template in ColorTemplate.values)
            Expanded(
              child: Semantics(
                inMutuallyExclusiveGroup: true,
                checked: template == current,
                button: true,
                label: 'Couleur ${template.label}',
                excludeSemantics: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref
                        .read(appearanceControllerProvider.notifier)
                        .setTemplate(template);
                  },
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: AppMotion.short,
                        width: 40,
                        height: 40,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          borderRadius: AppRadius.brButton,
                          border: Border.all(
                            color: template == current
                                ? t.textPrimary
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: template.swatch,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(4),
                            ),
                          ),
                          child: template == current
                              ? const Icon(
                                  Icons.check_rounded,
                                  size: 18,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        template.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: template == current
                              ? t.textPrimary
                              : t.textSecondary,
                          fontWeight: template == current
                              ? FontWeight.w600
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Les polices, chacune présentée dans sa propre famille (« Aa » et son nom) :
/// une police se choisit à l'œil, pas sur un nom de fichier.
class _FontSelector extends ConsumerWidget {
  const _FontSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final text = context.textTheme;
    final current = ref.watch(appearanceControllerProvider).font;

    return AppSurface(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final font in FontChoice.values) ...[
            if (font != FontChoice.values.first)
              Divider(height: 1, thickness: 0.5, color: t.border, indent: 64),
            Semantics(
              inMutuallyExclusiveGroup: true,
              checked: font == current,
              button: true,
              label: 'Police ${font.label}',
              excludeSemantics: true,
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  ref.read(appearanceControllerProvider.notifier).setFont(font);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 36,
                        child: Text(
                          'Aa',
                          style: font.preview(
                            TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: font == current ? t.brand : t.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(font.label, style: text.titleMedium),
                            Text(
                              font.sample,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      AnimatedOpacity(
                        opacity: font == current ? 1 : 0,
                        duration: AppMotion.short,
                        child: Icon(
                          Icons.check_rounded,
                          size: 20,
                          color: t.brand,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
