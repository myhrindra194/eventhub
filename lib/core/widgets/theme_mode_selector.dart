import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/extensions/context_x.dart';
import 'package:eventhub/core/widgets/app_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sélecteur de thème à trois positions : Automatique, Clair, Sombre.
///
/// Trois tuiles toujours visibles plutôt qu'un menu : le thème est un réglage
/// que l'on cherche du regard, et voir les trois choix côte à côte, avec le
/// choix courant surligné, répond en un coup d'œil à « où je change ça ? ».
/// Le changement est immédiat et mémorisé sur l'appareil
/// ([ThemeModeController]).
///
/// « Automatique » vient en premier et reste la valeur par défaut : une
/// application qui contrarie le réglage système se remarque pour de mauvaises
/// raisons.
///
/// Partagé par Profil et Paramètres : un seul composant, un seul
/// comportement, où qu'on règle le thème.
class ThemeModeSelector extends ConsumerWidget {
  const ThemeModeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(themeModeControllerProvider);
    final t = context.tokens;

    return AppSurface(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          for (final mode in ThemeMode.values)
            Expanded(
              child: Semantics(
                inMutuallyExclusiveGroup: true,
                checked: mode == current,
                button: true,
                label: 'Thème ${mode.label}',
                excludeSemantics: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(themeModeControllerProvider.notifier).set(mode);
                  },
                  child: AnimatedContainer(
                    duration: AppMotion.short,
                    curve: AppMotion.standard,
                    margin: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: mode == current ? t.brandSoft : t.surfaceSunken,
                      borderRadius: AppRadius.brButton,
                      border: Border.all(
                        color: mode == current ? t.brand : Colors.transparent,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          mode.icon,
                          size: 22,
                          color: mode == current ? t.brand : t.textSecondary,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          mode.label,
                          style: context.textTheme.titleSmall?.copyWith(
                            color: mode == current ? t.brand : t.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
