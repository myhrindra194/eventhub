import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/organizer/application/organizer_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Organizer shell: Événements · Stats · Alertes · Profil.
///
/// The order follows the organizer's loop: act on events, read how they
/// perform, react to what changed, then the account. Creation, editing and
/// the guest list are still pushed *over* the shell rather than hidden in a
/// tab — they are tasks, not places.
///
/// The "Alertes" destination carries a dot while the watchlist is not empty
/// (an event starting within 24 h, last seats, sold out): it clears itself
/// when the situation does, so it never nags about something already
/// handled.
class OrganizerShell extends ConsumerWidget {
  const OrganizerShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watchCount = ref.watch(organizerWatchlistProvider).value?.length ?? 0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: AppNavBar(
        selectedIndex: navigationShell.currentIndex,
        onSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: [
          const NavDestination(
            icon: Icons.dashboard_outlined,
            selectedIcon: Icons.dashboard_rounded,
            label: AppStrings.events,
          ),
          const NavDestination(
            icon: Icons.insights_outlined,
            selectedIcon: Icons.insights_rounded,
            label: AppStrings.stats,
          ),
          NavDestination(
            icon: Icons.notifications_none_rounded,
            selectedIcon: Icons.notifications_rounded,
            label: AppStrings.alerts,
            badgeCount: watchCount,
          ),
          const NavDestination(
            icon: Icons.person_outline_rounded,
            selectedIcon: Icons.person_rounded,
            label: AppStrings.profile,
          ),
        ],
      ),
    );
  }
}
