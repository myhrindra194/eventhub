import 'package:eventhub/core/config/app_config.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/reservations/application/reservation_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Participant shell: Explorer · Recherche · Billets · Profil.
///
/// The "Billets" destination carries a dot as soon as the user holds an
/// upcoming ticket — a passive reminder that costs no screen space and
/// answers the question people actually open the app for ("c'est quand
/// déjà ?").
class ParticipantShell extends ConsumerWidget {
  const ParticipantShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider)();
    final upcoming = ref
        .watch(myReservationsProvider)
        .maybeWhen(
          data: (list) => list
              .where((r) => r.isActive && r.eventStartsAt.isAfter(now))
              .length,
          orElse: () => 0,
        );

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: AppNavBar(
        selectedIndex: navigationShell.currentIndex,
        onSelected: (index) => navigationShell.goBranch(
          index,
          // Tapping the active tab pops its stack back to the root — the
          // behaviour every large app implements and users expect.
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: [
          const NavDestination(
            icon: Icons.explore_outlined,
            selectedIcon: Icons.explore_rounded,
            label: AppStrings.explore,
          ),
          const NavDestination(
            icon: Icons.search_rounded,
            selectedIcon: Icons.search_rounded,
            label: AppStrings.search,
          ),
          NavDestination(
            icon: Icons.confirmation_number_outlined,
            selectedIcon: Icons.confirmation_number_rounded,
            label: AppStrings.tickets,
            badgeCount: upcoming,
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
