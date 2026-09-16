import 'package:eventhub/app/theme/theme.dart';
import 'package:flutter/material.dart';

/// Un groupe de lignes de formulaire partageant une seule carte, séparées par
/// des filets.
///
/// C'est le motif « inset grouped » d'iOS, et il mérite sa place : un
/// formulaire de connexion est *un* objet — une identité — et non quatre
/// boîtes flottantes. Le regroupement réduit trois bordures à une, supprime
/// l'échelle d'espaces entre les champs, et fait lire l'ensemble comme une
/// seule zone à toucher.
///
/// La contrepartie : une ligne ne peut plus porter son propre contour, donc
/// le focus et l'erreur s'expriment par une teinte de fond et par un texte
/// sous la ligne.
class FieldGroup extends StatelessWidget {
  const FieldGroup({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: AppRadius.brButton,
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, thickness: 1, color: t.borderSubtle),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Une ligne de [FieldGroup] : un glyphe en tête, le champ, et une commande
/// facultative en fin de ligne.
///
/// Le focus teinte la ligne de la surface de marque au lieu de dessiner un
/// contour : à l'intérieur d'une carte groupée, un contour entrerait en
/// concurrence avec la bordure de la carte elle-même.
class FieldRow extends StatefulWidget {
  const FieldRow({
    required this.icon,
    required this.controller,
    super.key,
    this.hint,
    this.label,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
    this.validator,
    this.onFieldSubmitted,
    this.obscureText = false,
    this.trailing,
    this.onChanged,
    this.enabled = true,
  });

  final IconData icon;
  final TextEditingController controller;
  final String? hint;

  /// Libellé facultatif, de largeur fixe, à gauche de la valeur — comme les
  /// lignes « Nom / Email / Téléphone » de la référence.
  final String? label;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onFieldSubmitted;
  final bool obscureText;
  final Widget? trailing;
  final ValueChanged<String>? onChanged;
  final bool enabled;

  @override
  State<FieldRow> createState() => _FieldRowState();
}

class _FieldRowState extends State<FieldRow> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final focused = _focus.hasFocus;

    return AnimatedContainer(
      duration: AppMotion.short,
      curve: AppMotion.standard,
      color: focused ? t.brandSoft : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      constraints: const BoxConstraints(minHeight: 56),
      child: Row(
        children: [
          Icon(
            widget.icon,
            size: 19,
            color: focused ? t.brand : t.textTertiary,
          ),
          const SizedBox(width: AppSpacing.md),
          if (widget.label != null)
            SizedBox(
              width: 86,
              child: Text(widget.label!, style: text.bodySmall),
            ),
          Expanded(
            child: TextFormField(
              controller: widget.controller,
              focusNode: _focus,
              enabled: widget.enabled,
              obscureText: widget.obscureText,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              textCapitalization: widget.textCapitalization,
              autofillHints: widget.autofillHints,
              validator: widget.validator,
              onFieldSubmitted: widget.onFieldSubmitted,
              onChanged: widget.onChanged,
              style: text.bodyLarge,
              decoration: InputDecoration(
                hintText: widget.hint,
                filled: false,
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.lg,
                ),
                errorStyle: text.bodySmall?.copyWith(
                  color: t.danger.fg,
                  height: 1.3,
                ),
              ),
            ),
          ),
          if (widget.trailing != null) ...[
            const SizedBox(width: AppSpacing.sm),
            widget.trailing!,
          ],
        ],
      ),
    );
  }
}

/// Case à cocher carrée à coins de 6 px — utilisée pour « Se souvenir de
/// moi » et l'acceptation des conditions.
class AppCheckbox extends StatelessWidget {
  const AppCheckbox({
    required this.value,
    required this.onChanged,
    required this.label,
    super.key,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget label;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: AppMotion.xshort,
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: value ? t.brand : Colors.transparent,
              borderRadius: AppRadius.brButton,
              border: Border.all(
                color: value ? t.brand : t.borderStrong,
                width: 1.5,
              ),
            ),
            child: value
                ? Icon(Icons.check_rounded, size: 15, color: t.textOnBrand)
                : null,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: label),
        ],
      ),
    );
  }
}

/// « ou continuer avec » — un filet de chaque côté d'une légende.
class LabelledDivider extends StatelessWidget {
  const LabelledDivider({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Row(
      children: [
        Expanded(child: Divider(color: t.border, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        Expanded(child: Divider(color: t.border, height: 1)),
      ],
    );
  }
}

/// Une [FieldRow] qui détient son propre état de masquage et expose l'œil
/// pour le basculer.
///
/// Dans une carte groupée, ce bascule est une icône plutôt que le mot
/// « Afficher » : la ligne porte déjà un glyphe en tête et une valeur, et un
/// troisième élément de texte transformerait une ligne de 56 px en
/// paragraphe.
class PasswordFieldRow extends StatefulWidget {
  const PasswordFieldRow({
    required this.controller,
    super.key,
    this.hint,
    this.label,
    this.validator,
    this.textInputAction = TextInputAction.done,
    this.onFieldSubmitted,
    this.autofillHints,
    this.onChanged,
    this.icon = Icons.lock_outline_rounded,
  });

  final TextEditingController controller;
  final String? hint;
  final String? label;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onChanged;
  final IconData icon;

  @override
  State<PasswordFieldRow> createState() => _PasswordFieldRowState();
}

class _PasswordFieldRowState extends State<PasswordFieldRow> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return FieldRow(
      icon: widget.icon,
      controller: widget.controller,
      hint: widget.hint,
      label: widget.label,
      obscureText: _obscure,
      validator: widget.validator,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onFieldSubmitted,
      autofillHints: widget.autofillHints,
      onChanged: widget.onChanged,
      trailing: IconButton(
        onPressed: () => setState(() => _obscure = !_obscure),
        icon: Icon(
          _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          size: 20,
          color: t.textTertiary,
        ),
        tooltip: _obscure ? 'Afficher' : 'Masquer',
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
