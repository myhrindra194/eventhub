import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/extensions/context_x.dart';
import 'package:eventhub/features/auth/domain/entities/user_role.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// « Vous êtes : Participant · Organisateur », le choix obligatoire du
/// formulaire d'inscription.
///
/// Deux tuiles côte à côte plutôt qu'une liste déroulante : il n'y a que deux
/// réponses, et voir les deux en même temps, avec la phrase qui décrit
/// chacune, évite de choisir au hasard. Aucune n'est présélectionnée — une
/// valeur par défaut ferait de la question une formalité, alors qu'elle
/// décide de l'espace dans lequel l'app s'ouvrira.
///
/// Sémantiquement, c'est un groupe de boutons radio : un lecteur d'écran
/// annonce « sélectionné » sur la tuile choisie.
class RoleChoice extends StatelessWidget {
  const RoleChoice({
    required this.value,
    required this.onChanged,
    super.key,
    this.errorText,
  });

  final UserRole? value;
  final ValueChanged<UserRole> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final role in UserRole.values) ...[
                if (role != UserRole.values.first)
                  const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _RoleTile(
                    role: role,
                    selected: value == role,
                    hasError: errorText != null,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onChanged(role);
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            errorText!,
            style: context.textTheme.bodySmall?.copyWith(color: t.danger.fg),
          ),
        ],
      ],
    );
  }
}

class _RoleTile extends StatelessWidget {
  const _RoleTile({
    required this.role,
    required this.selected,
    required this.hasError,
    required this.onTap,
  });

  final UserRole role;
  final bool selected;
  final bool hasError;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = context.textTheme;
    final border = selected
        ? t.brand
        : hasError
        ? t.danger.fg
        : t.border;

    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      child: Material(
        color: selected ? t.brandSoft : t.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.brButton,
          side: BorderSide(color: border, width: selected ? 1.5 : 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        role.label,
                        style: text.titleSmall?.copyWith(
                          color: selected ? t.brand : t.textPrimary,
                        ),
                      ),
                    ),
                    // Un disque plein ou vide, pas une icône : le repère
                    // radio que tout le monde lit sans légende.
                    AnimatedContainer(
                      duration: AppMotion.short,
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? t.brand : t.borderStrong,
                          width: selected ? 5 : 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  role.description,
                  style: text.bodySmall?.copyWith(
                    color: t.textSecondary,
                    height: 1.4,
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
