import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/config/app_config.dart';
import 'package:eventhub/core/extensions/context_x.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/utils/date_formats.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/auth/application/auth_providers.dart';
import 'package:eventhub/features/events/domain/entities/event.dart';
import 'package:eventhub/features/moderation/domain/report.dart';
import 'package:eventhub/features/moderation/presentation/widgets/report_sheet.dart';
import 'package:eventhub/features/reviews/application/review_providers.dart';
import 'package:eventhub/features/reviews/domain/review.dart';
import 'package:eventhub/features/reviews/presentation/widgets/review_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Les avis sur le détail d’un événement : résumé, distribution, derniers
/// avis, et l’invitation à en laisser un quand l’utilisateur y a droit.
///
/// Invisible avant le début de l’événement tant que personne n’a donné son
/// avis — un bloc « Avis » vide sur un événement à venir n’est que du bruit.
class ReviewsSection extends ConsumerWidget {
  const ReviewsSection({required this.event, super.key});

  final Event event;

  static const _preview = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviews =
        ref.watch(eventReviewsProvider(event.id)).value ?? const <Review>[];
    final mine = ref.watch(myReviewProvider(event.id)).value;
    final canReview = ref.watch(canReviewEventProvider(event.id));
    final now = ref.watch(clockProvider)();
    if (!event.hasStarted(now) && reviews.isEmpty) {
      return const SizedBox.shrink();
    }

    final summary = ReviewSummary.of(reviews);
    final text = context.textTheme;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xxxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const SectionLabel(AppStrings.reviews),
              const Spacer(),
              if (summary.count > 0)
                Text(
                  AppStrings.reviewsCount(summary.count),
                  style: text.bodySmall,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (summary.count == 0)
            Text(AppStrings.noReviews, style: text.bodyMedium)
          else ...[
            _Summary(summary: summary),
            const SizedBox(height: AppSpacing.lg),
            for (final review in reviews.take(_preview))
              _ReviewTile(review: review),
            if (reviews.length > _preview)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => _showAll(context, reviews),
                  child: Text(AppStrings.seeAllReviews(reviews.length)),
                ),
              ),
          ],
          if (mine?.hidden ?? false) ...[
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: context.tokens.warning.bg,
                border: Border(
                  left: BorderSide(
                    color: context.tokens.warning.solid,
                    width: 3,
                  ),
                ),
              ),
              child: Text(
                AppStrings.reviewHiddenNotice,
                style: text.bodySmall?.copyWith(
                  color: context.tokens.warning.fg,
                  height: 1.45,
                ),
              ),
            ),
          ],
          if (canReview) ...[
            const SizedBox(height: AppSpacing.lg),
            AppButton.secondary(
              label: mine == null
                  ? AppStrings.leaveReview
                  : AppStrings.editReview,
              onPressed: () =>
                  showReviewSheet(context, eventId: event.id, existing: mine),
            ),
          ],
        ],
      ),
    );
  }

  void _showAll(BuildContext context, List<Review> reviews) {
    showAppSheet<void>(
      context: context,
      builder: (_) => AppSheet(
        title: AppStrings.reviews,
        subtitle: AppStrings.reviewsCount(reviews.length),
        child: ListView(
          shrinkWrap: true,
          children: [for (final r in reviews) _ReviewTile(review: r)],
        ),
      ),
    );
  }
}

class Stars extends StatelessWidget {
  const Stars({required this.value, super.key, this.size = 16});

  /// 0..5, demi-étoiles rendues.
  final double value;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            value >= i
                ? Icons.star_rounded
                : value >= i - 0.5
                ? Icons.star_half_rounded
                : Icons.star_border_rounded,
            size: size,
            color: value >= i - 0.5 ? t.warning.solid : t.borderStrong,
          ),
      ],
    );
  }
}

/// La moyenne en grands caractères, puis une barre par niveau d’étoiles. Une
/// seule teinte (la couleur de la note) avec l’effectif imprimé à côté de
/// chaque barre : les barres donnent la forme, les chiffres portent la
/// valeur.
class _Summary extends StatelessWidget {
  const _Summary({required this.summary});

  final ReviewSummary summary;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = context.textTheme;
    final max = summary.distribution.reduce((a, b) => a > b ? a : b);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              summary.average.toStringAsFixed(1).replaceAll('.', ','),
              style: text.displaySmall?.copyWith(height: 1),
            ),
            const SizedBox(height: AppSpacing.xs),
            Stars(value: summary.average),
          ],
        ),
        const SizedBox(width: AppSpacing.xl),
        Expanded(
          child: Column(
            children: [
              for (var star = 5; star >= 1; star--)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 14,
                        child: Text('$star', style: text.labelSmall),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (_, box) => Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              height: 6,
                              width: max == 0
                                  ? 0
                                  : box.maxWidth *
                                        summary.distribution[star - 1] /
                                        max,
                              decoration: BoxDecoration(
                                color: t.warning.solid,
                                borderRadius: const BorderRadius.horizontal(
                                  right: Radius.circular(AppRadius.button),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      SizedBox(
                        width: 22,
                        child: Text(
                          '${summary.distribution[star - 1]}',
                          textAlign: TextAlign.right,
                          style: text.labelSmall?.copyWith(
                            letterSpacing: 0,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReviewTile extends ConsumerWidget {
  const _ReviewTile({required this.review});

  final Review review;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final text = context.textTheme;
    final user = ref.watch(currentUserProvider);
    final canReport = user != null && user.id != review.authorId;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: t.borderSubtle)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppAvatar(name: review.authorName, size: 34),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        review.authorName,
                        style: text.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      AppDateFormats.shortDate(review.createdAt),
                      style: text.labelSmall?.copyWith(letterSpacing: 0),
                    ),
                    if (canReport)
                      SizedBox(
                        width: 32,
                        height: 24,
                        child: PopupMenuButton<ReportTarget>(
                          tooltip: AppStrings.reportAction,
                          padding: EdgeInsets.zero,
                          iconSize: 18,
                          icon: Icon(
                            Icons.more_horiz_rounded,
                            color: t.textTertiary,
                          ),
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppRadius.brButton,
                          ),
                          onSelected: (target) => showReportSheet(
                            context,
                            target: target,
                            targetId: review.id,
                            subject: review.authorName,
                          ),
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: ReportTarget.review,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.flag_outlined,
                                    size: 18,
                                    color: t.danger.fg,
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  const Text(AppStrings.reportAction),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs),
                Stars(value: review.rating.toDouble(), size: 14),
                if (review.comment.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    review.comment,
                    style: text.bodyMedium?.copyWith(
                      color: t.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
