import 'package:eventhub/app/theme/theme.dart';
import 'package:flutter/material.dart';

/// Une ligne de formulaire avec son libellé.
///
/// Le libellé se place *au-dessus* du champ plutôt que de flotter dedans :
/// avec un libellé en guise de texte indicatif, l'utilisateur perd la
/// question dès qu'il commence à répondre — c'est la cause classique
/// d'abandon d'un formulaire. Un [hint] facultatif porte la contrainte
/// (« 5 Mo max », « min. 6 caractères ») avant qu'on puisse s'y tromper, si
/// bien que l'erreur de validation devient l'exception et non le parcours.
class LabeledField extends StatelessWidget {
  const LabeledField({
    required this.label,
    required this.child,
    super.key,
    this.hint,
    this.isRequired = false,
    this.trailing,
  });

  final String label;
  final Widget child;
  final String? hint;
  final bool isRequired;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.xs),
          child: Row(
            children: [
              // Pas d'astérisque rouge : il crie « formulaire administratif »
              // sur chaque ligne. Un champ obligatoire se signale par son
              // message de validation, et les lecteurs d'écran l'annoncent
              // grâce au libellé sémantique ci-dessous.
              Semantics(
                label: isRequired ? '$label, obligatoire' : label,
                excludeSemantics: true,
                child: Text(
                  label,
                  style: text.titleSmall?.copyWith(color: t.textPrimary),
                ),
              ),
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
        ),
        if (hint != null) ...[
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.xs),
            child: Text(hint!, style: text.bodySmall),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        child,
      ],
    );
  }
}

/// Le champ de recherche.
///
/// Deux modes, et c'est voulu :
///  * interactif — la frappe part directement dans [onChanged] ;
///  * [readOnly] avec [onTap] — un champ *leurre* sur l'accueil, qui ouvre
///    l'onglet de recherche. Il garde la commande visible sans charger toute
///    la machinerie de recherche dans le fil.
class AppSearchField extends StatelessWidget {
  const AppSearchField({
    required this.hint,
    super.key,
    this.controller,
    this.onChanged,
    this.onClear,
    this.onTap,
    this.onSubmitted,
    this.readOnly = false,
    this.autofocus = false,
    this.value = '',
    this.trailing,
  });

  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final VoidCallback? onTap;
  final ValueChanged<String>? onSubmitted;
  final bool readOnly;
  final bool autofocus;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return TextField(
      controller: controller,
      autofocus: autofocus,
      readOnly: readOnly,
      onTap: onTap,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: TextInputAction.search,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: t.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        // Le champ doit mesurer exactement [AppSizes.inputHeight] : c'est ce
        // qui lui permet de partager sa ligne avec le bouton de filtre sans
        // qu'aucun des deux ne dépasse de l'autre.
        prefixIcon: Icon(Icons.search_rounded, color: t.textTertiary, size: 20),
        suffixIcon:
            trailing ??
            (value.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.cancel_rounded, size: 18),
                    color: t.textTertiary,
                    onPressed: onClear,
                    tooltip: 'Effacer',
                  )),
        border: _border(t.border),
        enabledBorder: _border(t.border),
        focusedBorder: _border(t.brand, width: 1.6),
      ),
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: AppRadius.brInput,
        borderSide: BorderSide(color: color, width: width),
      );
}

/// Ligne en lecture seule qui ouvre un sélecteur — date, heure, catégorie.
///
/// Habillée exactement comme un champ de saisie, pour que le formulaire se
/// lise comme une surface cohérente, mais elle porte un chevron qui annonce
/// qu'un appui ouvre quelque chose.
class PickerField extends StatelessWidget {
  const PickerField({
    required this.value,
    required this.icon,
    required this.onTap,
    super.key,
    this.placeholder,
    this.trailingIcon = Icons.expand_more_rounded,
  });

  final String? value;
  final String? placeholder;
  final IconData icon;
  final IconData trailingIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final hasValue = value != null && value!.isNotEmpty;

    return Material(
      color: t.surfaceSunken,
      borderRadius: AppRadius.brInput,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: AppSizes.inputHeight,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: AppRadius.brInput,
            border: Border.all(color: t.border),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: t.textTertiary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  hasValue ? value! : (placeholder ?? ''),
                  style: text.bodyLarge?.copyWith(
                    color: hasValue ? t.textPrimary : t.textTertiary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(trailingIcon, size: 20, color: t.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
