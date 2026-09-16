import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/config/app_config.dart';
import 'package:eventhub/core/extensions/context_x.dart';
import 'package:eventhub/core/firebase/firebase_providers.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/support/presentation/widgets/support_page.dart';
import 'package:eventhub/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// À propos d’EventHub.
///
/// Trois principes plutôt qu’un paragraphe marketing — chacun est un
/// comportement que l’utilisateur peut vérifier dans l’application — puis les
/// faits techniques par lesquels commence une conversation avec le support
/// (version, environnement).
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  static const version = '1.0.0';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);

    return SupportPage(
      title: AppStrings.about,
      eyebrow: 'EventHub $version',
      headline: 'Des événements, sans friction.',
      lead:
          'EventHub relie celles et ceux qui organisent à celles et ceux qui '
          'viennent : une jauge juste, un billet dans la poche, une liste '
          "d'invités à jour.",
      children: [
        const NumberedSection(
          number: '01',
          title: 'Une place est une place',
          body:
              'Chaque réservation est une transaction : deux personnes ne '
              'peuvent pas obtenir la dernière place, et un événement complet '
              'ne se surréserve jamais.',
        ),
        const NumberedSection(
          number: '02',
          title: 'Tout le monde voit la même jauge',
          body:
              'Une réservation ou une annulation met à jour la capacité sur '
              'tous les écrans ouverts, sans rafraîchir.',
        ),
        const NumberedSection(
          number: '03',
          title: 'Deux rôles, deux espaces',
          body:
              'Les participants découvrent et réservent, les organisateurs '
              'publient et suivent. Aucun écran ne mélange les deux.',
        ),
        const SectionLabel('Informations'),
        const SizedBox(height: AppSpacing.md),
        _Rows(
          children: [
            const _Row(label: AppStrings.version, value: version),
            _Row(label: 'Environnement', value: config.flavor.name),
            _Row(
              label: 'Données',
              value: ref.watch(firestoreProvider).app.options.projectId,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),
        const SectionLabel('Aller plus loin'),
        const SizedBox(height: AppSpacing.md),
        _Rows(
          children: [
            _Row(
              label: AppStrings.helpCenter,
              onTap: () => context.push(AppRoutes.help),
            ),
            _Row(
              label: AppStrings.privacy,
              onTap: () => context.push(AppRoutes.privacyPolicy),
            ),
          ],
        ),
      ],
    );
  }
}

class _Rows extends StatelessWidget {
  const _Rows({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => AppSurface(
    padding: EdgeInsets.zero,
    child: Column(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const AppDivider(height: 1),
          children[i],
        ],
      ],
    ),
  );
}

/// Un libellé avec soit une valeur (un fait), soit un chevron (un lien) —
/// jamais les deux.
class _Row extends StatelessWidget {
  const _Row({required this.label, this.value, this.onTap});

  final String label;
  final String? value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = context.textTheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        child: Row(
          children: [
            Expanded(child: Text(label, style: text.titleMedium)),
            if (value != null)
              Text(
                value!,
                style: text.bodyMedium?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              )
            else
              Icon(Icons.chevron_right_rounded, color: t.textTertiary),
          ],
        ),
      ),
    );
  }
}
