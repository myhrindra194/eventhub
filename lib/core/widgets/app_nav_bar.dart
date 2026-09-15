import 'dart:ui';

import 'package:eventhub/app/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// One destination of the floating navigation bar.
class NavDestination {
  const NavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.badgeCount,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;

  /// Optional counter rendered as a dot on the icon.
  final int? badgeCount;
}

/// Floating frosted navigation bar.
///
/// Design decisions worth stating, because they are what make it feel
/// finished rather than default:
///  * it **floats** with a margin instead of sticking to the screen edge,
///    so content scrolls visibly underneath and the app feels layered;
///  * only the selected destination shows its label, inside a gradient
///    pill — the label appears where the eye already is, and the bar stays
///    uncluttered at four items;
///  * the transition is a single animated container, so switching tabs
///    reads as one object moving rather than four objects blinking;
///  * a light haptic fires on selection: on a phone, navigation without
///    physical feedback feels laggy even when it is not.
///
/// Screens must pad the bottom of their scrollables with
/// [AppSizes.navBarInset] so the last item clears the bar.
class AppNavBar extends StatelessWidget {
  const AppNavBar({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  final List<NavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        bottom + AppSpacing.md,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: AppSizes.navBarHeight,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            decoration: BoxDecoration(
              color: t.glass,
              borderRadius: BorderRadius.circular(AppRadius.xxl),
              border: Border.all(color: t.borderStrong),
              boxShadow: t.shadows.lg,
            ),
            child: Row(
              children: [
                for (var i = 0; i < destinations.length; i++)
                  // The selected destination is the only one showing a label,
                  // so it needs more room than the icon-only ones. Equal
                  // `Expanded` slots overflow at four destinations on a 360 dp
                  // screen — caught by running the app, never by the analyzer.
                  Expanded(
                    flex: i == selectedIndex ? 2 : 1,
                    child: _NavButton(
                      destination: destinations[i],
                      selected: i == selectedIndex,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onSelected(i);
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final NavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final color = selected ? t.textOnBrand : t.textSecondary;

    return Semantics(
      selected: selected,
      button: true,
      label: destination.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Center(
          child: AnimatedContainer(
            duration: AppMotion.medium,
            curve: AppMotion.emphasized,
            padding: EdgeInsets.symmetric(
              horizontal: selected ? AppSpacing.md : AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              gradient: selected ? t.brandGradient : null,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: t.brand.withValues(alpha: 0.38),
                        blurRadius: 16,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Icon(
                  icon: selected ? destination.selectedIcon : destination.icon,
                  color: color,
                  badgeCount: destination.badgeCount,
                ),
                if (selected) ...[
                  const SizedBox(width: AppSpacing.sm),
                  // Flexible + ellipsis is the safety net: whatever the label
                  // length or the user's text scale, the pill can shrink
                  // instead of overflowing its slot.
                  Flexible(
                    child: Text(
                      destination.label,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: text.labelLarge?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Icon extends StatelessWidget {
  const _Icon({required this.icon, required this.color, this.badgeCount});

  final IconData icon;
  final Color color;
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final showBadge = (badgeCount ?? 0) > 0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon, size: 22, color: color),
        if (showBadge)
          Positioned(
            top: -2,
            right: -3,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: t.accent,
                shape: BoxShape.circle,
                border: Border.all(color: t.glass, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }
}
