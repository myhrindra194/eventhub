import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/config/app_config.dart';
import 'package:eventhub/core/extensions/context_x.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Settings.
///
/// Kept short on purpose. The appearance selector is the only setting with
/// real teeth today; the notification switches are local placeholders that
/// mark where the push feature will plug in, and they are labelled as such
/// rather than pretending to work.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _reminders = true;
  bool _news = false;

  @override
  Widget build(BuildContext context) {
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
          AppSurface(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            elevation: SurfaceElevation.flat,
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _reminders,
                  onChanged: (v) => setState(() => _reminders = v),
                  title: Text(
                    AppStrings.notificationsReminder,
                    style: context.textTheme.titleMedium,
                  ),
                  subtitle: Text(
                    AppStrings.notificationsReminderHint,
                    style: context.textTheme.bodySmall,
                  ),
                ),
                const AppDivider(height: 1),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _news,
                  onChanged: (v) => setState(() => _news = v),
                  title: Text(
                    AppStrings.notificationsNews,
                    style: context.textTheme.titleMedium,
                  ),
                  subtitle: Text(
                    AppStrings.notificationsNewsHint,
                    style: context.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          const SectionLabel(AppStrings.about),
          const SizedBox(height: AppSpacing.md),
          AppSurface(
            elevation: SurfaceElevation.flat,
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
                    borderRadius: AppRadius.brSm,
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
