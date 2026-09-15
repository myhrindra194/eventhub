import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/extensions/context_x.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/core/utils/date_formats.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/admin/application/moderation_providers.dart';
import 'package:eventhub/features/admin/domain/moderation.dart';
import 'package:eventhub/features/auth/application/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Who administers EventHub, and how to add or remove someone.
///
/// Granting works by email on an existing account: the claim lives in the
/// token, so the person sees the moderation area after signing in again.
/// Nobody can remove their own role here — the last admin can never lock the
/// project out by mistake.
class AdminRolesScreen extends ConsumerStatefulWidget {
  const AdminRolesScreen({super.key});

  @override
  ConsumerState<AdminRolesScreen> createState() => _AdminRolesScreenState();
}

class _AdminRolesScreenState extends ConsumerState<AdminRolesScreen> {
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _grant() async {
    FocusScope.of(context).unfocus();
    final email = _email.text.trim();
    final result = await ref
        .read(moderationControllerProvider.notifier)
        .setAdmin(email: email, admin: true);
    if (!mounted) return;
    switch (result) {
      case Ok():
        _email.clear();
        context.showSuccess(AppStrings.adminGranted(email));
      case Err(:final failure):
        context.showFailure(failure);
    }
  }

  Future<void> _revoke(AdminAccount admin) async {
    final confirmed = await showConfirmSheet(
      context,
      icon: Icons.remove_moderator_outlined,
      title: AppStrings.revokeAdminTitle,
      message: AppStrings.revokeAdminMessage(admin.email),
      confirmLabel: AppStrings.revokeAdmin,
    );
    if (!confirmed || !mounted) return;
    final result = await ref
        .read(moderationControllerProvider.notifier)
        .setAdmin(email: admin.email, admin: false);
    if (!mounted) return;
    switch (result) {
      case Ok():
        context.showSuccess(AppStrings.adminRevoked(admin.email));
      case Err(:final failure):
        context.showFailure(failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = context.textTheme;
    final me = ref.watch(currentUserProvider);
    final admins = ref.watch(adminAccountsProvider).value ?? const [];
    final busy = ref.watch(moderationControllerProvider).isLoading;

    return AppScaffold(
      dense: true,
      appBar: AppBar(title: const Text(AppStrings.adminRolesTitle)),
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
          const SizedBox(height: AppSpacing.lg),
          FieldGroup(
            children: [
              FieldRow(
                icon: Icons.alternate_email_rounded,
                controller: _email,
                hint: AppStrings.adminEmailHint,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                enabled: !busy,
                onChanged: (_) => setState(() {}),
                onFieldSubmitted: (_) => _grant(),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton.primary(
            label: AppStrings.grantAdmin,
            elevated: false,
            isLoading: busy,
            loadingLabel: AppStrings.decisionSending,
            onPressed: _email.text.trim().isEmpty || busy ? null : _grant,
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
                      AppSpacing.sm,
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
                                admins[i].email,
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
                          const Padding(
                            padding: EdgeInsets.only(right: AppSpacing.sm),
                            child: AppBadge(
                              label: AppStrings.you,
                              tone: AppTone.neutral,
                              dense: true,
                            ),
                          )
                        else
                          TextButton(
                            onPressed: busy ? null : () => _revoke(admins[i]),
                            style: TextButton.styleFrom(
                              foregroundColor: t.danger.fg,
                              shape: const RoundedRectangleBorder(
                                borderRadius: AppRadius.brButton,
                              ),
                            ),
                            child: const Text(AppStrings.revokeAdmin),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            AppStrings.adminRelogHint,
            style: text.bodySmall?.copyWith(height: 1.45),
          ),
        ],
      ),
    );
  }
}
