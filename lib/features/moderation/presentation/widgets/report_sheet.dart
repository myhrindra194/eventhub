import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/extensions/context_x.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/moderation/application/report_providers.dart';
import 'package:eventhub/features/moderation/domain/report.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens the report form for [target] / [targetId]. [subject] is what the
/// user sees being reported (event title, organizer or author name).
Future<void> showReportSheet(
  BuildContext context, {
  required ReportTarget target,
  required String targetId,
  required String subject,
}) {
  return showAppSheet<void>(
    context: context,
    builder: (_) => _ReportSheet(
      pageContext: context,
      target: target,
      targetId: targetId,
      subject: subject,
    ),
  );
}

/// A closed list of reasons, each with one line saying what it covers, then
/// an optional note. The send button stays disabled until a reason is
/// chosen: a report without a reason is one a moderator cannot triage.
class _ReportSheet extends ConsumerStatefulWidget {
  const _ReportSheet({
    required this.pageContext,
    required this.target,
    required this.targetId,
    required this.subject,
  });

  /// The page under the sheet: confirmation toasts are raised there once the
  /// sheet is gone, otherwise they would slide in behind it.
  final BuildContext pageContext;
  final ReportTarget target;
  final String targetId;
  final String subject;

  @override
  ConsumerState<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends ConsumerState<_ReportSheet> {
  final _details = TextEditingController();
  ReportReason? _reason;
  String? _error;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    final result = await ref
        .read(reportControllerProvider.notifier)
        .submit(
          target: widget.target,
          targetId: widget.targetId,
          reason: _reason,
          details: _details.text,
        );
    if (!mounted) return;

    switch (result) {
      case Ok():
        Navigator.of(context).pop();
        if (widget.pageContext.mounted) {
          widget.pageContext.showSuccess(AppStrings.reportSent);
        }
      case Err(
        failure: BusinessRuleFailure(rule: BusinessRule.alreadyReported) &&
            final failure,
      ):
        Navigator.of(context).pop();
        if (widget.pageContext.mounted) {
          widget.pageContext.showToast(failure.message);
        }
      case Err(:final failure):
        setState(() => _error = failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = context.textTheme;
    final busy = ref.watch(reportControllerProvider).isLoading;

    return AppSheet(
      title: AppStrings.reportTitle,
      subtitle: '${widget.target.label} · ${widget.subject}',
      actions: [
        AppButton(
          label: AppStrings.reportSend,
          variant: AppButtonVariant.danger,
          icon: Icons.flag_outlined,
          elevated: false,
          isLoading: busy,
          loadingLabel: AppStrings.reportSending,
          onPressed: _reason == null || busy ? null : _submit,
        ),
      ],
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.reportLead,
              style: text.bodySmall?.copyWith(height: 1.5),
            ),
            const SizedBox(height: AppSpacing.lg),
            const SectionLabel(AppStrings.reportReasonLabel),
            const SizedBox(height: AppSpacing.sm),
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: AppRadius.brButton,
                border: Border.all(color: t.border),
              ),
              child: Column(
                children: [
                  for (final reason in ReportReason.values) ...[
                    if (reason.index > 0)
                      Divider(height: 1, color: t.borderSubtle),
                    _ReasonRow(
                      reason: reason,
                      selected: reason == _reason,
                      onTap: busy
                          ? null
                          : () => setState(() {
                              _reason = reason;
                              _error = null;
                            }),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _details,
              enabled: !busy,
              minLines: 2,
              maxLines: 5,
              maxLength: ReportPolicy.maxDetails,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: _reason == ReportReason.other
                    ? AppStrings.reportDetails
                    : '${AppStrings.reportDetails} (facultatif)',
                hintText: AppStrings.reportDetailsHint,
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

class _ReasonRow extends StatelessWidget {
  const _ReasonRow({
    required this.reason,
    required this.selected,
    required this.onTap,
  });

  final ReportReason reason;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = context.textTheme;

    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          color: selected ? t.danger.bg : null,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 18,
                height: 18,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? t.danger.solid : t.borderStrong,
                    width: selected ? 5 : 1.5,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(reason.label, style: text.titleSmall),
                    const SizedBox(height: 2),
                    Text(reason.description, style: text.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
