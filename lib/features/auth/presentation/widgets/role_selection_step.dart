import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';

enum UserRole { participant, organizer }

/// Étape 2 de l'inscription : "Your Profile" — choix du rôle
/// (Participant ou Organisateur).
class RoleSelectionStep extends StatelessWidget {
  final bool isDark;
  final UserRole selectedRole;
  final bool isLoading;
  final ValueChanged<UserRole> onRoleChanged;
  final VoidCallback onCreateAccount;
  final VoidCallback onGoBack;

  const RoleSelectionStep({
    super.key,
    required this.isDark,
    required this.selectedRole,
    required this.isLoading,
    required this.onRoleChanged,
    required this.onCreateAccount,
    required this.onGoBack,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: size.width * 0.08,
        vertical: size.height * 0.04,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Your Profile', style: AppTypography.display(isDark)),
          const SizedBox(height: 6),
          Text(
            "Tell us how you'll use EventHub",
            style: AppTypography.bodyLarge(isDark),
          ),
          const SizedBox(height: 32),

          Text(
            'CHOOSE YOUR ROLE',
            style: AppTypography.caption(isDark).copyWith(
              color: textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),

          _RoleCard(
            isDark: isDark,
            title: 'Participant',
            description: 'Découvrir et réserver des événements uniques.',
            icon: Icons.confirmation_number_outlined,
            isSelected: selectedRole == UserRole.participant,
            onTap: () => onRoleChanged(UserRole.participant),
          ),
          const SizedBox(height: 16),
          _RoleCard(
            isDark: isDark,
            title: 'Organisateur',
            description: 'Créer et gérer vos propres événements.',
            icon: Icons.event_available_outlined,
            isSelected: selectedRole == UserRole.organizer,
            onTap: () => onRoleChanged(UserRole.organizer),
          ),

          SizedBox(height: size.height * 0.08),

          AppButton(
            text: 'Create Account',
            isLoading: isLoading,
            onPressed: onCreateAccount,
          ),
          const SizedBox(height: 20),

          Center(
            child: TextButton(
              onPressed: onGoBack,
              child: Text(
                'Go Back',
                style: AppTypography.heading3(isDark).copyWith(
                  color: textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final bool isDark;
  final String title;
  final String description;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.isDark,
    required this.title,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final surfaceColor =
        isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? AppColors.accentIndigo
                : textSecondary.withValues(alpha: 0.15),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.accentIndigo.withValues(alpha: 0.2)
                    : textSecondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.accentIndigo : textSecondary,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.heading3(isDark)),
                  const SizedBox(height: 4),
                  Text(description, style: AppTypography.body(isDark)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _RadioIndicator(
                isSelected: isSelected, textSecondary: textSecondary),
          ],
        ),
      ),
    );
  }
}

class _RadioIndicator extends StatelessWidget {
  final bool isSelected;
  final Color textSecondary;

  const _RadioIndicator({
    required this.isSelected,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? AppColors.accentIndigo : Colors.transparent,
        border: Border.all(
          color: isSelected
              ? AppColors.accentIndigo
              : textSecondary.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: isSelected
          ? const Icon(Icons.check, size: 15, color: Colors.white)
          : null,
    );
  }
}