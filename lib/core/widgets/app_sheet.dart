import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/widgets/app_button.dart';
import 'package:flutter/material.dart';

/// Ouvre une feuille modale avec l'habillage du produit déjà appliqué : coins
/// supérieurs à 6 px, voile, marges de zone sûre, contrôle du défilement.
///
/// Les feuilles sont préférées aux boîtes de dialogue dès qu'il y a plus
/// d'une ligne de contenu : elles restent à portée du pouce, elles peuvent
/// grandir, et les refermer d'un glissement pardonne davantage que viser un
/// petit « Annuler ».
///
/// Il n'y a **volontairement pas de poignée**. La barrette de préhension est
/// une convention iOS qui se lit comme du décor de gabarit ; chaque feuille
/// porte à la place un bouton de fermeture explicite, et le glissement vers
/// le bas continue de fonctionner.
Future<T?> showAppSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  bool isDismissible = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    enableDrag: isDismissible,
    useSafeArea: true,
    // Posé ici en plus du thème, pour qu'une feuille reste correcte même sous
    // un thème qui ne viendrait pas d'`AppTheme`.
    showDragHandle: false,
    clipBehavior: Clip.antiAlias,
    shape: const RoundedRectangleBorder(borderRadius: AppRadius.brModalSheet),
    backgroundColor: context.tokens.surfaceOverlay,
    barrierColor: context.tokens.scrim,
    builder: builder,
  );
}

/// La mise en page standard à l'intérieur d'une feuille.
///
/// Trois bandes séparées par des filets — en-tête, contenu, actions — plutôt
/// qu'une seule colonne centrée : l'en-tête dit ce qu'est la feuille et
/// comment en sortir, le contenu défile pour son propre compte, et les
/// actions restent ancrées en bas quelle que soit la longueur du contenu.
class AppSheet extends StatelessWidget {
  const AppSheet({
    required this.title,
    required this.child,
    super.key,
    this.subtitle,
    this.actions = const [],
    this.padding = const EdgeInsets.all(AppSpacing.xl),
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget> actions;

  /// Marge intérieure de la bande de contenu.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: text.headlineSmall),
                          if (subtitle != null) ...[
                            const SizedBox(height: AppSpacing.xxs),
                            Text(subtitle!, style: text.bodyMedium),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  const SheetCloseButton(),
                ],
              ),
            ),
            Divider(height: 1, thickness: 1, color: t.borderSubtle),
            Flexible(
              child: Padding(padding: padding, child: child),
            ),
            if (actions.isNotEmpty) ...[
              Divider(height: 1, thickness: 1, color: t.borderSubtle),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: actions,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Le ✕ carré au rayon de commande de 6 px — la sortie explicite qui
/// remplace la poignée de glissement.
class SheetCloseButton extends StatelessWidget {
  const SheetCloseButton({super.key, this.onPressed});

  /// Par défaut, referme la feuille sans renvoyer de résultat.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return IconButton(
      onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
      tooltip: 'Fermer',
      icon: const Icon(Icons.close_rounded, size: 20),
      style: IconButton.styleFrom(
        foregroundColor: t.textSecondary,
        backgroundColor: t.surfaceSunken,
        fixedSize: const Size.square(36),
        minimumSize: const Size.square(36),
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.brButton,
          side: BorderSide(color: t.border),
        ),
      ),
    );
  }
}

/// Feuille de confirmation d'une action irréversible.
///
/// Alignée à gauche, comme une lettre et non comme une fenêtre surgissante :
/// un carré teinté de 6 px portant le sujet, la conséquence écrite en toutes
/// lettres, puis les deux choix. Le bouton destructeur se place **au-dessus**
/// d'« Annuler », pour que l'option sûre soit la plus proche du pouce.
/// Renvoie `false` en cas d'abandon, jamais `null`.
Future<bool> showConfirmSheet(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Annuler',
  IconData icon = Icons.delete_outline_rounded,
  AppTone tone = AppTone.danger,
}) async {
  final result = await showAppSheet<bool>(
    context: context,
    builder: (context) {
      final colors = context.tokens.resolve(tone);
      final text = Theme.of(context).textTheme;

      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colors.bg,
                      borderRadius: AppRadius.brButton,
                      border: Border.all(color: colors.border),
                    ),
                    child: Icon(icon, size: 22, color: colors.fg),
                  ),
                  const Spacer(),
                  SheetCloseButton(
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
              // Le contenu conserve la gouttière xl à droite, alors même que
              // la ligne d'en-tête rapproche le bouton de fermeture du bord.
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.lg),
                    Text(title, style: text.headlineSmall),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      message,
                      style: text.bodyMedium?.copyWith(height: 1.5),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    AppButton(
                      label: confirmLabel,
                      variant: tone == AppTone.danger
                          ? AppButtonVariant.danger
                          : AppButtonVariant.primary,
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppButton.secondary(
                      label: cancelLabel,
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
  return result ?? false;
}
