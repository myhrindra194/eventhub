import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/analytics/analytics_consent.dart';
import 'package:eventhub/core/config/app_config.dart';
import 'package:eventhub/core/extensions/context_x.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/core/widgets/appearance_settings.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/auth/application/auth_providers.dart';
import 'package:eventhub/features/auth/presentation/widgets/delete_account_sheet.dart';
import 'package:eventhub/features/notifications/application/notification_providers.dart';
import 'package:eventhub/features/notifications/domain/notification_preferences.dart';
import 'package:eventhub/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Réglages.
///
/// Chaque interrupteur ici fait vraiment quelque chose. Les préférences de
/// notification sont stockées dans Firestore et lues par les Cloud Functions
/// avant chaque envoi : un interrupteur éteint arrête donc la toute prochaine
/// push. Seules les notifications qui existent réellement pour le rôle sont
/// proposées : un participant reçoit des rappels, un organisateur des alertes
/// de réservation — aucune bascule pour un message que personne n’envoie.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);

    return AppScaffold(
      dense: true,
      appBar: AppTopBar.subPage(
        title: AppStrings.settings,
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
          const SectionLabel(AppStrings.appearance),
          const SizedBox(height: AppSpacing.md),
          const AppearanceSettings(),
          const SizedBox(height: AppSpacing.xxl),
          const SectionLabel(AppStrings.account),
          const SizedBox(height: AppSpacing.md),
          AppSurface(
            padding: EdgeInsets.zero,
            child: InkWell(
              onTap: () => context.push(AppRoutes.changePassword),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 20,
                      color: context.tokens.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Text(
                        AppStrings.changePassword,
                        style: context.textTheme.titleMedium,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: context.tokens.textTertiary,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          const SectionLabel(AppStrings.notifications),
          const SizedBox(height: AppSpacing.md),
          const _NotificationSwitches(),
          const SizedBox(height: AppSpacing.md),
          const _AnalyticsSwitch(),
          const SizedBox(height: AppSpacing.xxl),
          SectionLabel(AppStrings.dangerZone, color: context.tokens.danger.fg),
          const SizedBox(height: AppSpacing.md),
          AppSurface(
            padding: EdgeInsets.zero,
            borderColor: context.tokens.danger.border,
            child: InkWell(
              onTap: () => showDeleteAccountSheet(context),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Icon(
                      Icons.person_remove_outlined,
                      size: 20,
                      color: context.tokens.danger.fg,
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Text(
                        AppStrings.deleteAccount,
                        style: context.textTheme.titleMedium?.copyWith(
                          color: context.tokens.danger.fg,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: context.tokens.textTertiary,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          const SectionLabel(AppStrings.about),
          const SizedBox(height: AppSpacing.md),
          AppSurface(
            child: Column(
              children: [
                _InfoRow(
                  label: AppStrings.version,
                  value: '1.0.0 (${config.flavor.name})',
                ),
                const AppDivider(),
                const _InfoRow(label: 'Design system', value: 'Aurora v2'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationSwitches extends ConsumerWidget {
  const _NotificationSwitches();

  Future<void> _save(
    BuildContext context,
    WidgetRef ref,
    NotificationPreferences next,
  ) async {
    final result = await ref
        .read(notificationPreferencesControllerProvider.notifier)
        .save(next);
    if (result case Err(:final failure) when context.mounted) {
      context.showFailure(failure);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final prefs = ref.watch(notificationPreferencesProvider).value;
    final saving = ref
        .watch(notificationPreferencesControllerProvider)
        .isLoading;
    final enabled = prefs != null && !saving;

    final (title, hint, value, apply) = (user?.isOrganizer ?? false)
        ? (
            AppStrings.notificationsBookings,
            AppStrings.notificationsBookingsHint,
            prefs?.bookingAlerts ?? true,
            (bool v) => prefs!.copyWith(bookingAlerts: v),
          )
        : (
            AppStrings.notificationsReminder,
            AppStrings.notificationsReminderHint,
            prefs?.eventReminders ?? true,
            (bool v) => prefs!.copyWith(eventReminders: v),
          );

    return AppSurface(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      child: Column(
        children: [
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: value,
            onChanged: enabled ? (v) => _save(context, ref, apply(v)) : null,
            title: Text(title, style: context.textTheme.titleMedium),
            subtitle: Text(hint, style: context.textTheme.bodySmall),
          ),
          const AppDivider(height: 1),
          // Les deux rôles peuvent suivre des organisateurs (F-10).
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: prefs?.followedOrganizers ?? true,
            onChanged: enabled
                ? (v) =>
                      _save(context, ref, prefs.copyWith(followedOrganizers: v))
                : null,
            title: Text(
              AppStrings.notificationsFollowed,
              style: context.textTheme.titleMedium,
            ),
            subtitle: Text(
              AppStrings.notificationsFollowedHint,
              style: context.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

/// Consentement à la mesure d’audience, modifiable à tout moment (même
/// stockage que la feuille de première connexion).
class _AnalyticsSwitch extends ConsumerWidget {
  const _AnalyticsSwitch();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consent = ref.watch(analyticsConsentProvider);
    return AppSurface(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      child: SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        value: consent.value ?? false,
        onChanged: consent.hasValue
            ? (v) => ref.read(analyticsConsentProvider.notifier).set(v)
            : null,
        title: Text(
          AppStrings.analyticsSetting,
          style: context.textTheme.titleMedium,
        ),
        subtitle: Text(
          AppStrings.analyticsSettingHint,
          style: context.textTheme.bodySmall,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(label, style: context.textTheme.titleMedium),
      const Spacer(),
      Text(value, style: context.textTheme.bodyMedium),
    ],
  );
}
