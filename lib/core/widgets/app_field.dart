import 'package:eventhub/app/theme/theme.dart';
import 'package:flutter/material.dart';

/// A labelled form row.
///
/// The label sits *above* the field rather than floating inside it: with a
/// label-in-placeholder the user loses the question as soon as they start
/// typing, which is the classic source of form abandonment. An optional
/// [hint] carries the constraint ("5 Mo max", "min. 6 caractères") before
/// the user can get it wrong, so validation errors become the exception.
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
              Text(
                label,
                style: text.titleSmall?.copyWith(color: t.textPrimary),
              ),
              if (isRequired)
                Text(
                  ' *',
                  style: text.titleSmall?.copyWith(color: t.danger.fg),
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

/// Search input.
///
/// Two modes on purpose:
///  * interactive — types straight into [onChanged];
///  * [readOnly] with [onTap] — a *fake* field on the home screen that
///    navigates to the real search page. It keeps the affordance visible
///    without loading the search machinery on the feed.
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
          vertical: AppSpacing.md,
        ),
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

/// Read-only row that opens a picker (date, time, category).
///
/// Styled exactly like a text input so the form reads as one coherent
/// surface, but it carries a chevron to advertise that tapping opens
/// something.
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
