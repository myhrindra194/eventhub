import 'package:eventhub/app/theme/theme.dart';
import 'package:flutter/material.dart';

/// A group of form rows sharing one card, separated by hairlines.
///
/// The iOS "inset grouped" pattern, and it earns its place: a login form is
/// *one* object — an identity — not four floating boxes. Grouping collapses
/// three borders into one, removes the ladder of gaps between fields, and
/// makes the whole block read as a single tap target region.
///
/// The trade-off is that a row cannot carry its own outline, so focus and
/// error are expressed by a background tint and by text under the row.
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

/// One row of a [FieldGroup]: a leading glyph, the input, an optional
/// trailing affordance.
///
/// Focus tints the row with the brand surface instead of drawing a ring —
/// inside a grouped card an outline would fight the card's own border.
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

  /// Optional fixed-width caption on the left of the value, as in the
  /// reference's "Nom / Email / Téléphone" rows.
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

/// Square checkbox with a rounded 7 px corner, as in the reference — used for
/// "Se souvenir de moi" and the terms acceptance.
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
              borderRadius: const BorderRadius.all(Radius.circular(7)),
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

/// "ou continuer avec" — a hairline on each side of a caption.
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

/// A [FieldRow] that owns its own masking state and exposes the eye toggle.
///
/// Inside a grouped card the toggle is an icon rather than the word
/// "Afficher": the row is already carrying a leading glyph and a value, and a
/// third text element would turn a 56 px line into a paragraph.
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
