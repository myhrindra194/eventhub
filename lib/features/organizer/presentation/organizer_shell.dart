import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/organizer/application/organizer_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Coque de l’organisateur : Événements · Stats · Alertes · Profil.
///
/// L’ordre suit la boucle de l’organisateur : agir sur les événements, lire
/// comment ils se comportent, réagir à ce qui a changé, puis le compte. La
/// création, l’édition et la liste des invités sont toujours empilées *par
/// dessus* la coque plutôt que cachées dans un onglet — ce sont des tâches,
/// pas des lieux.
///
/// La destination « Alertes » porte une pastille tant que la liste de
/// surveillance n’est pas vide (un événement qui commence dans moins de 24 h,
/// dernières places, complet) : elle s’efface d’elle-même quand la situation
/// se résout, et ne harcèle donc jamais à propos de quelque chose de déjà
/// traité.
class OrganizerShell extends ConsumerWidget {
  const OrganizerShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watchCount = ref.watch(organizerWatchlistProvider).value?.length ?? 0;

    return AdaptiveNavigation(
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
      child: navigationShell,
    );
  }
}
