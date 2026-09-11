import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/auth/domain/entities/user_role.dart';
import 'package:flutter/material.dart';

/// Role picker.
///
/// Cards rather than a dropdown or a segmented control: the role decides
/// which half of the product the user gets, so it deserves a description
/// and a clear selected state, not a one-line label. The choice is
/// **immutable** once the account exists — the security rules enforce it —
/// which is exactly why the UI must make it hard to pick by accident.
class RoleSelector extends StatelessWidget {
  const RoleSelector({required this.value, required this.onChanged, super.key});

  final UserRole value;
  final ValueChanged<UserRole> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final role in UserRole.values) ...[
          _RoleCard(
            role: role,
            selected: role == value,
            onTap: () => onChanged(role),
          ),
          if (role != UserRole.values.last)
            const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.selected,
    required this.onTap,
  });

  final UserRole role;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    final (icon, perks) = switch (role) {
      UserRole.participant => (
        Icons.local_activity_rounded,
        ['Explorer le catalogue', 'Réserver en un tap', 'Gérer ses billets'],
      ),
      UserRole.organizer => (
        Icons.workspace_premium_rounded,
        ['Publier des événements', 'Suivre le remplissage', 'Voir la liste'],
      ),
    };

    return AnimatedContainer(
      duration: AppMotion.short,
      curve: AppMotion.standard,
      decoration: BoxDecoration(
        color: selected ? t.brandSoft : t.surfaceSunken,
        borderRadius: AppRadius.brButton,
        border: Border.all(
          color: selected ? t.brand : t.border,
          width: selected ? 1.6 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadius.brButton,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconTile(
                      icon: icon,
                      color: selected ? t.brand : t.textSecondary,
                      background: selected ? t.surface : t.surface,
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(role.label, style: text.titleLarge),
                          const SizedBox(height: 2),
                          Text(role.description, style: text.bodySmall),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Icon(
                      selected
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked,
                      color: selected ? t.brand : t.borderStrong,
                      size: 24,
                    ),
                  ],
                ),
                AnimatedSize(
                  duration: AppMotion.medium,
                  curve: AppMotion.emphasized,
                  child: selected
                      ? Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.lg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final perk in perks)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppSpacing.sm,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.check_rounded,
                                        size: 14,
                                        color: t.brand,
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Text(perk, style: text.bodySmall),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
