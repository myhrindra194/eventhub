import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/analytics/analytics_consent.dart';
import 'package:eventhub/core/config/app_config.dart';
import 'package:eventhub/core/extensions/context_x.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/auth/application/auth_providers.dart';
import 'package:eventhub/features/auth/presentation/widgets/delete_account_sheet.dart';
import 'package:eventhub/features/notifications/application/notification_providers.dart';
import 'package:eventhub/features/notifications/domain/notification_preferences.dart';
import 'package:eventhub/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Settings.
///
/// Every switch here does something real. Notification preferences are
/// stored in Firestore and read by the Cloud Functions before each send, so
/// a switch turned off stops the very next push. Only the notifications that
/// actually exist for the role are offered: a participant gets reminders, an
/// organizer gets booking alerts — no toggle for a message nobody sends.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);

    return AppScaffold(
      dense: true,
      appBar: AppBar(title: const Text(AppStrings.settings)),
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
          const _ThemeSelector(),
          const SizedBox(height: AppSpacing.xxl),
          const SectionLabel(AppStrings.account),
          const SizedBox(height: AppSpacing.md),
          AppSurface(
            padding: EdgeInsets.zero,
            elevation: SurfaceElevation.flat,
            radius: AppRadius.button,
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
            elevation: SurfaceElevation.flat,
            radius: AppRadius.button,
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
            elevation: SurfaceElevation.flat,
            radius: AppRadius.button,
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
      elevation: SurfaceElevation.flat,
      radius: AppRadius.button,
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
          // Both roles may follow organizers (F-10).
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

/// Consent to audience measurement, changeable at any time (same storage as
/// the first-sign-in sheet).
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
      elevation: SurfaceElevation.flat,
      radius: AppRadius.button,
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

/// Three-way appearance picker.
///
/// "Automatique" is offered first and is the default: an app that fights
/// the system setting is an app people notice for the wrong reason.
class _ThemeSelector extends ConsumerWidget {
  const _ThemeSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(themeModeControllerProvider);
    final t = context.tokens;

    return AppSurface(
      padding: const EdgeInsets.all(AppSpacing.md),
      elevation: SurfaceElevation.flat,
      radius: AppRadius.button,
      child: Row(
        children: [
          for (final mode in ThemeMode.values)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () =>
                    ref.read(themeModeControllerProvider.notifier).set(mode),
                child: AnimatedContainer(
                  duration: AppMotion.short,
                  curve: AppMotion.standard,
                  margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
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
                      const SizedBox(height: AppSpacing.sm),
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
        ],
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
