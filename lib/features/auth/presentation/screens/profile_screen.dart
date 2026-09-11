import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/config/app_config.dart';
import 'package:eventhub/core/extensions/context_x.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/core/utils/date_formats.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/auth/application/auth_controller.dart';
import 'package:eventhub/features/auth/application/auth_providers.dart';
import 'package:eventhub/features/auth/domain/entities/app_user.dart';
import 'package:eventhub/features/events/application/event_providers.dart';
import 'package:eventhub/features/reservations/application/reservation_providers.dart';
import 'package:eventhub/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Profile — identity, a few numbers that matter, and the way out.
///
/// The same screen serves both roles: the identity block is shared, only
/// the statistics differ. Duplicating it per role would double the
/// maintenance for a header and an avatar.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmSheet(
      context,
      icon: Icons.logout_rounded,
      title: AppStrings.logoutTitle,
      message: AppStrings.logoutConfirm,
      confirmLabel: AppStrings.logout,
    );
    if (!confirmed || !context.mounted) return;

    final result = await ref.read(authControllerProvider.notifier).signOut();
    if (!context.mounted) return;
    if (result case Err(:final failure)) context.showFailure(failure);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const AppScaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final settingsPath = user.isOrganizer
        ? AppRoutes.organizerSettings
        : AppRoutes.settings;

    return AppScaffold(
      constrainWidth: false,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.lg,
            AppSpacing.gutter,
            AppSizes.navBarInset,
          ),
          children: [
            _IdentityCard(user: user),
            const SizedBox(height: AppSpacing.xl),
            _Stats(user: user),
            const SizedBox(height: AppSpacing.xxl),
            const SectionLabel(AppStrings.account),
            const SizedBox(height: AppSpacing.md),
            _MenuGroup(
              items: [
                _MenuItem(
                  icon: Icons.badge_outlined,
                  label: AppStrings.editProfile,
                  onTap: () => context.showToast(AppStrings.comingSoon),
                ),
                _MenuItem(
                  icon: Icons.tune_rounded,
                  label: AppStrings.settings,
                  onTap: () => context.push(settingsPath),
                ),
                _MenuItem(
                  icon: Icons.notifications_none_rounded,
                  label: AppStrings.notifications,
                  onTap: () => context.push(settingsPath),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            const SectionLabel(AppStrings.support),
            const SizedBox(height: AppSpacing.md),
            _MenuGroup(
              items: [
                _MenuItem(
                  icon: Icons.help_outline_rounded,
                  label: AppStrings.helpCenter,
                  onTap: () => context.showToast(AppStrings.comingSoon),
                ),
                _MenuItem(
                  icon: Icons.shield_outlined,
                  label: AppStrings.privacy,
                  onTap: () => context.showToast(AppStrings.comingSoon),
                ),
                _MenuItem(
                  icon: Icons.info_outline_rounded,
                  label: AppStrings.about,
                  onTap: () => context.showToast(AppStrings.comingSoon),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            AppButton.secondary(
              label: AppStrings.logout,
              icon: Icons.logout_rounded,
              onPressed: () => _signOut(context, ref),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gradient identity header. The role is shown as a badge rather than a
/// line of text: it is the single piece of information that changes what
/// the whole app does, so it deserves to be unmissable.
class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: t.brandGradient,
        borderRadius: AppRadius.brXxl,
        boxShadow: [
          BoxShadow(
            color: t.brand.withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24, width: 2),
            ),
            child: AppAvatar(name: user.name, size: 62),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: text.headlineSmall?.copyWith(color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style: text.bodySmall?.copyWith(color: Colors.white70),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: AppRadius.brPill,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            user.isOrganizer
                                ? Icons.workspace_premium_rounded
                                : Icons.local_activity_rounded,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            user.role.label.toUpperCase(),
                            style: text.labelSmall?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (user.createdAt != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '${AppStrings.memberSince} '
                    '${AppDateFormats.shortDate(user.createdAt!)}',
                    style: text.labelSmall?.copyWith(
                      color: Colors.white70,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stats extends ConsumerWidget {
  const _Stats({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider)();

    if (user.isOrganizer) {
      final events = ref.watch(organizerEventsProvider(user.id)).value ?? [];
      final booked = events.fold<int>(0, (sum, e) => sum + e.reservedCount);
      final capacity = events.fold<int>(0, (sum, e) => sum + e.capacity);
      final rate = capacity == 0 ? 0 : (booked / capacity * 100).round();

      return Row(
        children: [
          Expanded(
            child: StatTile(
              value: '${events.length}',
              label: AppStrings.totalEvents,
              icon: Icons.event_note_rounded,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: StatTile(
              value: '$booked',
              label: AppStrings.totalParticipants,
              icon: Icons.groups_2_rounded,
              tone: AppTone.info,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: StatTile(
              value: '$rate%',
              label: AppStrings.fillRate,
              icon: Icons.insights_rounded,
              tone: AppTone.success,
            ),
          ),
        ],
      );
    }

    final reservations = ref.watch(myReservationsProvider).value ?? [];
    final upcoming = reservations
        .where((r) => r.isActive && r.eventStartsAt.isAfter(now))
        .length;
    final attended = reservations
        .where((r) => r.isActive && !r.eventStartsAt.isAfter(now))
        .length;

    return Row(
      children: [
        Expanded(
          child: StatTile(
            value: '$upcoming',
            label: AppStrings.upcoming,
            icon: Icons.confirmation_number_rounded,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: StatTile(
            value: '$attended',
            label: AppStrings.pastEvents,
            icon: Icons.history_rounded,
            tone: AppTone.info,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: StatTile(
            value: '${reservations.length}',
            label: AppStrings.myReservations,
            icon: Icons.style_rounded,
            tone: AppTone.success,
          ),
        ),
      ],
    );
  }
}

class _MenuItem {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  }) : trailing = null;

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;
}

/// Grouped rows sharing one surface, iOS-settings style — dividers between
/// items instead of a card per row, which halves the visual noise.
class _MenuGroup extends StatelessWidget {
  const _MenuGroup({required this.items});

  final List<_MenuItem> items;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return AppSurface(
      padding: EdgeInsets.zero,
      elevation: SurfaceElevation.flat,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const AppDivider(indent: 60, height: 1),
            InkWell(
              onTap: items[i].onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.lg,
                ),
                child: Row(
                  children: [
                    Icon(items[i].icon, size: 20, color: t.textSecondary),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Text(
                        items[i].label,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    items[i].trailing ??
                        Icon(
                          Icons.chevron_right_rounded,
                          color: t.textTertiary,
                        ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
