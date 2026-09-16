import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/extensions/context_x.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/utils/date_formats.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/admin/application/moderation_providers.dart';
import 'package:eventhub/features/auth/application/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Qui administre EventHub — et pourquoi cet écran n’a aucun bouton.
///
/// Le rôle, c’est le document `admins/{uid}`, que les règles de sécurité
/// rendent non écrivable par tout client, administrateurs compris. C’est
/// délibéré : faute de code serveur, un bouton « attribuer le rôle » devrait
/// être une écriture client, et une écriture client capable de créer un
/// administrateur n’est qu’à une session volée de devenir tout le back-office.
/// La liste est donc en lecture seule, et l’écran dit, en toutes lettres, où
/// le rôle s’attribue réellement.
class AdminRolesScreen extends ConsumerWidget {
  const AdminRolesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final text = context.textTheme;
    final me = ref.watch(currentUserProvider);
    final admins = ref.watch(adminAccountsProvider).value ?? const [];

    return AppScaffold(
      dense: true,
      appBar: AppTopBar.subPage(
        title: AppStrings.adminRolesTitle,
        onBack: () => context.pop(),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          AppSpacing.lg,
          AppSpacing.gutter,
          AppSpacing.huge,
        ),
        children: [
          Text(
            AppStrings.adminRolesLead,
            style: text.bodySmall?.copyWith(height: 1.5),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Row(
            children: [
              const SectionLabel(AppStrings.adminRolesTitle),
              const Spacer(),
              Text('${admins.length}', style: text.labelMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: AppRadius.brButton,
              border: Border.all(color: t.border),
            ),
            child: Column(
              children: [
                for (var i = 0; i < admins.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: t.borderSubtle),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      AppSpacing.md,
                    ),
                    child: Row(
                      children: [
                        AppAvatar(
                          name: admins[i].name ?? admins[i].email,
                          size: 36,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                admins[i].email.isEmpty
                                    ? admins[i].id
                                    : admins[i].email,
                                style: text.titleSmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (admins[i].grantedAt != null)
                                Text(
                                  AppStrings.adminSince(
                                    AppDateFormats.shortDate(
                                      admins[i].grantedAt!,
                                    ),
                                  ),
                                  style: text.bodySmall,
                                ),
                            ],
                          ),
                        ),
                        if (admins[i].id == me?.id)
                          const AppBadge(
                            label: AppStrings.you,
                            tone: AppTone.neutral,
                            dense: true,
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          const SectionLabel(AppStrings.adminGrantTitle),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: t.surfaceSunken,
              border: Border(left: BorderSide(color: t.borderStrong, width: 3)),
            ),
            child: Text(
              AppStrings.adminGrantSteps,
              style: text.bodySmall?.copyWith(height: 1.6),
            ),
          ),
        ],
      ),
    );
  }
}
