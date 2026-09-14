import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/extensions/context_x.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/admin/application/moderation_providers.dart';
import 'package:eventhub/features/admin/domain/moderation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Confirms a moderation decision: its consequence in plain words, the note
/// (required when a person loses something), then the button.
Future<void> showModerationDecisionSheet(
  BuildContext context, {
  required ModerationEntry entry,
  required ModerationAction action,
}) => showAppSheet<void>(
  context: context,
  builder: (_) =>
      _DecisionSheet(pageContext: context, entry: entry, action: action),
);

class _DecisionSheet extends ConsumerStatefulWidget {
  const _DecisionSheet({
    required this.pageContext,
    required this.entry,
    required this.action,
  });

  final BuildContext pageContext;
  final ModerationEntry entry;
  final ModerationAction action;

  @override
  ConsumerState<_DecisionSheet> createState() => _DecisionSheetState();
}

class _DecisionSheetState extends ConsumerState<_DecisionSheet> {
  final _note = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    setState(() => _error = null);
    final result = await ref
        .read(moderationControllerProvider.notifier)
        .decide(entry: widget.entry, action: widget.action, note: _note.text);
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        Navigator.of(context).pop();
        if (widget.pageContext.mounted) {
          widget.pageContext.showSuccess(
            widget.action == ModerationAction.removeEvent
                ? AppStrings.eventRemovedToast(value ?? 0)
                : AppStrings.decisionSaved,
          );
        }
      case Err(:final failure):
        setState(() => _error = failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = context.textTheme;
    final action = widget.action;
    final busy = ref.watch(moderationControllerProvider).isLoading;
    final colors = t.resolve(
      action.destructive ? AppTone.danger : AppTone.brand,
    );

    return AppSheet(
      title: action.label,
      subtitle:
          '${widget.entry.target.label} · '
          '${AppStrings.reportsCount(widget.entry.reportCount)}',
      actions: [
        AppButton(
          label: action.label,
          variant: action.destructive
              ? AppButtonVariant.danger
              : AppButtonVariant.primary,
          elevated: false,
          isLoading: busy,
          loadingLabel: AppStrings.decisionSending,
          onPressed: busy ? null : _confirm,
        ),
      ],
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.bg,
                border: Border(left: BorderSide(color: colors.solid, width: 3)),
              ),
              child: Text(
                action.consequence,
                style: text.bodySmall?.copyWith(color: colors.fg, height: 1.5),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _note,
              enabled: !busy,
              minLines: 2,
              maxLines: 5,
              maxLength: ModerationPolicy.maxNote,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: action.requiresNote
                    ? AppStrings.decisionNoteRequired
                    : AppStrings.decisionNote,
                hintText: AppStrings.decisionNoteHint,
                alignLabelWithHint: true,
              ),
            ),
            if (_error != null)
              Text(
                _error!,
                style: text.bodySmall?.copyWith(color: t.danger.fg),
              ),
          ],
        ),
      ),
    );
  }
}
