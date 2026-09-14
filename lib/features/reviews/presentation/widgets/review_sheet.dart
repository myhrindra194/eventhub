import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/extensions/context_x.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/reviews/application/review_providers.dart';
import 'package:eventhub/features/reviews/domain/review.dart';
import 'package:eventhub/features/reviews/domain/review_policy.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Write or edit a review. [existing] pre-fills the form and adds "delete".
Future<void> showReviewSheet(
  BuildContext context, {
  required String eventId,
  Review? existing,
}) {
  final messenger = ScaffoldMessenger.of(context);
  return showAppSheet<void>(
    context: context,
    builder: (_) => _ReviewSheet(
      eventId: eventId,
      existing: existing,
      messenger: messenger,
    ),
  );
}

class _ReviewSheet extends ConsumerStatefulWidget {
  const _ReviewSheet({
    required this.eventId,
    required this.existing,
    required this.messenger,
  });

  final String eventId;
  final Review? existing;
  final ScaffoldMessengerState messenger;

  @override
  ConsumerState<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends ConsumerState<_ReviewSheet> {
  late int _rating = widget.existing?.rating ?? 0;
  late final _comment = TextEditingController(text: widget.existing?.comment);
  String? _error;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    final result = await ref
        .read(reviewControllerProvider.notifier)
        .save(eventId: widget.eventId, rating: _rating, comment: _comment.text);
    if (!mounted) return;
    _close(result, AppStrings.reviewPublished);
  }

  Future<void> _delete() async {
    final result = await ref
        .read(reviewControllerProvider.notifier)
        .delete(widget.eventId);
    if (!mounted) return;
    _close(result, AppStrings.reviewDeleted);
  }

  void _close(Result<void> result, String success) {
    switch (result) {
      case Ok():
        Navigator.of(context).pop();
        widget.messenger.showSnackBar(SnackBar(content: Text(success)));
      case Err(:final failure):
        setState(
          () => _error = failure is ValidationFailure
              ? failure.fieldErrors.values.first
              : failure.message,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = context.textTheme;
    final busy = ref.watch(reviewControllerProvider).isLoading;

    return AppSheet(
      title: widget.existing == null
          ? AppStrings.leaveReview
          : AppStrings.editReview,
      actions: [
        AppButton.primary(
          label: AppStrings.publishReview,
          isLoading: busy,
          elevated: false,
          onPressed: _rating == 0 ? null : _publish,
        ),
        if (widget.existing != null) ...[
          const SizedBox(height: AppSpacing.sm),
          AppButton.ghost(
            label: AppStrings.deleteReview,
            expand: true,
            onPressed: busy ? null : _delete,
          ),
        ],
      ],
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionLabel(AppStrings.ratingLabel),
            const SizedBox(height: AppSpacing.sm),
            Semantics(
              label: '${AppStrings.ratingLabel} : $_rating sur 5',
              child: Row(
                children: [
                  for (var star = 1; star <= 5; star++)
                    IconButton(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        setState(() => _rating = star);
                      },
                      tooltip: '$star étoile${star > 1 ? 's' : ''}',
                      iconSize: 34,
                      icon: Icon(
                        star <= _rating
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: star <= _rating
                            ? t.warning.solid
                            : t.borderStrong,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _comment,
              minLines: 3,
              maxLines: 6,
              maxLength: ReviewPolicy.maxCommentLength,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: AppStrings.commentHint,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _error!,
                style: text.bodySmall?.copyWith(color: t.danger.fg),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
