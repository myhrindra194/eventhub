import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/extensions/context_x.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/utils/date_formats.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/admin/application/moderation_providers.dart';
import 'package:eventhub/features/admin/domain/moderation.dart';
import 'package:eventhub/features/admin/presentation/widgets/moderation_decision_sheet.dart';
import 'package:eventhub/features/events/application/event_providers.dart';
import 'package:eventhub/features/moderation/domain/report.dart';
import 'package:eventhub/features/organizers/application/organizer_directory_providers.dart';
import 'package:eventhub/features/reviews/presentation/widgets/reviews_section.dart';
import 'package:eventhub/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Un dossier de modération : ce qui a été signalé, par combien de personnes
/// et pour quel motif, ce qui a déjà été décidé — et les décisions ouvertes
/// maintenant, épinglées en bas.
///
/// Le contenu est montré tel que son auteur l’a écrit (avis masqué compris),
/// parce qu’un modérateur juge le contenu, pas un résumé de celui-ci.
class ModerationEntryScreen extends ConsumerWidget {
  const ModerationEntryScreen({required this.entryId, super.key});

  final String entryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entry = ref.watch(moderationEntryProvider(entryId));

    return AppScaffold(
      dense: true,
      extendBody: false,
      appBar: AppTopBar.subPage(
        title: AppStrings.moderationEntryTitle,
        onBack: () => context.pop(),
      ),
      bottomBar: switch (entry.value) {
        final e? => _DecisionBar(entry: e),
        null => null,
      },
      body: AsyncValueWidget(
        value: entry,
        onRetry: () => ref.invalidate(moderationEntryProvider(entryId)),
        isEmpty: (e) => e == null,
        empty: const EmptyStateView(
          icon: Icons.folder_off_outlined,
          message: AppStrings.moderationEntryNotFound,
        ),
        data: (e) => ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.lg,
            AppSpacing.gutter,
            AppSpacing.huge,
          ),
          children: [
            _Header(entry: e!),
            const SizedBox(height: AppSpacing.xxl),
            const SectionLabel(AppStrings.reportedContent),
            const SizedBox(height: AppSpacing.md),
            _TargetPreview(entry: e),
            const SizedBox(height: AppSpacing.xxl),
            _Reports(entryId: e.id),
            const SizedBox(height: AppSpacing.xxl),
            _Decisions(entryId: e.id),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.entry});

  final ModerationEntry entry;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    final (statusLabel, tone) = switch (entry.status) {
      ModerationStatus.open => (AppStrings.statusOpen, AppTone.danger),
      ModerationStatus.resolved => (AppStrings.statusResolved, AppTone.success),
      ModerationStatus.dismissed => (
        AppStrings.statusDismissed,
        AppTone.neutral,
      ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SectionLabel(entry.target.label),
            const Spacer(),
            AppBadge(label: statusLabel, tone: tone, dense: true),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          AppStrings.reportsCount(entry.reportCount),
          style: text.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          entry.lastReason == null
              ? ''
              : '${AppStrings.lastReason} : ${entry.lastReason!.label}',
          style: text.bodySmall,
        ),
        if (entry.decision != null) ...[
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: context.tokens.surfaceSunken,
              border: Border(
                left: BorderSide(color: context.tokens.borderStrong, width: 3),
              ),
            ),
            child: Text(
              [
                entry.decision!.label,
                if (entry.decidedAt != null)
                  AppDateFormats.dayMonthTime(entry.decidedAt!),
                if ((entry.decisionNote ?? '').isNotEmpty) entry.decisionNote!,
              ].join(' · '),
              style: text.bodySmall?.copyWith(height: 1.45),
            ),
          ),
        ],
      ],
    );
  }
}

/// La chose signalée, lue en direct depuis sa propre collection.
class _TargetPreview extends ConsumerWidget {
  const _TargetPreview({required this.entry});

  final ModerationEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final text = context.textTheme;

    Widget frame(List<Widget> children) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: AppRadius.brButton,
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );

    Widget gone() => frame([
      Text(
        AppStrings.deletedContent,
        style: text.titleSmall?.copyWith(color: t.textSecondary),
      ),
    ]);

    Widget loading() => const Skeleton(height: 96);

    switch (entry.target) {
      case ReportTarget.event:
        final event = ref.watch(eventByIdProvider(entry.targetId));
        return event.when(
          loading: loading,
          error: (_, __) => gone(),
          data: (e) => e == null
              ? gone()
              : frame([
                  Text(e.title, style: text.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${AppDateFormats.dayMonthTime(e.startsAt)} · ${e.location}',
                    style: text.bodySmall,
                  ),
                  Text(
                    '${e.organizerName} · ${e.reservedCount} / ${e.capacity} '
                    '${AppStrings.seatsBookedSuffix}',
                    style: text.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    e.description,
                    style: text.bodyMedium?.copyWith(color: t.textSecondary),
                    maxLines: 8,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    onPressed: () => context.push(
                      AppRoutes.organizerPublicProfilePath(e.organizerId),
                    ),
                    child: const Text(AppStrings.openOrganizerProfile),
                  ),
                ]),
        );

      case ReportTarget.review:
        final review = ref.watch(moderatedReviewProvider(entry.targetId));
        return review.when(
          loading: loading,
          error: (_, __) => gone(),
          data: (r) => r == null
              ? gone()
              : frame([
                  Row(
                    children: [
                      AppAvatar(name: r.authorName, size: 32),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(r.authorName, style: text.titleSmall),
                      ),
                      if (r.hidden)
                        const AppBadge(
                          label: AppStrings.hiddenBadge,
                          tone: AppTone.warning,
                          dense: true,
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Stars(value: r.rating.toDouble()),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    r.comment.isEmpty ? AppStrings.emptyComment : r.comment,
                    style: text.bodyMedium?.copyWith(
                      color: r.comment.isEmpty
                          ? t.textTertiary
                          : t.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    AppDateFormats.dayMonthTime(r.updatedAt ?? r.createdAt),
                    style: text.labelSmall?.copyWith(letterSpacing: 0),
                  ),
                ]),
        );

      case ReportTarget.user:
        final account = ref.watch(reportedAccountProvider(entry.targetId));
        final profile = ref
            .watch(organizerProfileProvider(entry.targetId))
            .value;
        return account.when(
          loading: loading,
          error: (_, __) => gone(),
          data: (a) => a == null
              ? gone()
              : frame([
                  Row(
                    children: [
                      AppAvatar(name: a.name),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.name, style: text.titleMedium),
                            Text(a.email, style: text.bodySmall),
                          ],
                        ),
                      ),
                      if (a.suspended)
                        const AppBadge(
                          label: AppStrings.suspendedBadge,
                          tone: AppTone.danger,
                          dense: true,
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    [
                      if (a.role == 'organizer')
                        AppStrings.organizer
                      else
                        AppStrings.participantRole,
                      if (a.createdAt != null)
                        AppStrings.organizerSince(
                          AppDateFormats.shortDate(a.createdAt!),
                        ),
                      if (profile != null) ...[
                        '${profile.eventCount} ${AppStrings.eventsLabel(profile.eventCount)}',
                        '${profile.followerCount} ${AppStrings.followersLabel(profile.followerCount)}',
                      ],
                    ].join(' · '),
                    style: text.bodySmall,
                  ),
                  if (profile != null && profile.hasBio) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      profile.bio,
                      style: text.bodyMedium?.copyWith(color: t.textSecondary),
                    ),
                  ],
                  if (profile != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    TextButton(
                      onPressed: () => context.push(
                        AppRoutes.organizerPublicProfilePath(a.id),
                      ),
                      child: const Text(AppStrings.openOrganizerProfile),
                    ),
                  ],
                ]),
        );
    }
  }
}

class _Reports extends ConsumerWidget {
  const _Reports({required this.entryId});

  final String entryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final text = context.textTheme;
    final reports = ref.watch(moderationReportsProvider(entryId)).value ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const SectionLabel(AppStrings.reportsSection),
            const Spacer(),
            Text('${reports.length}', style: text.labelMedium),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        for (final r in reports)
          Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: t.borderSubtle)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        r.reason?.label ?? AppStrings.unknownReason,
                        style: text.titleSmall,
                      ),
                    ),
                    Text(
                      [
                        AppStrings.reporterLabel(r.reporterKey),
                        if (r.createdAt != null)
                          AppDateFormats.dayMonthTime(r.createdAt!),
                      ].join(' · '),
                      style: text.labelSmall?.copyWith(letterSpacing: 0),
                    ),
                  ],
                ),
                if (r.details.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    r.details,
                    style: text.bodyMedium?.copyWith(color: t.textSecondary),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _Decisions extends ConsumerWidget {
  const _Decisions({required this.entryId});

  final String entryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = context.textTheme;
    final decisions =
        ref.watch(moderationDecisionsProvider(entryId)).value ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel(AppStrings.decisionsSection),
        const SizedBox(height: AppSpacing.md),
        if (decisions.isEmpty)
          Text(AppStrings.noDecisionYet, style: text.bodySmall)
        else
          for (final d in decisions)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                [
                  d.action?.label ?? '—',
                  if (d.at != null) AppDateFormats.dayMonthTime(d.at!),
                  if (d.note.isNotEmpty) d.note,
                ].join(' · '),
                style: text.bodyMedium,
              ),
            ),
      ],
    );
  }
}

class _DecisionBar extends ConsumerWidget {
  const _DecisionBar({required this.entry});

  final ModerationEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewHidden =
        entry.target == ReportTarget.review &&
        (ref.watch(moderatedReviewProvider(entry.targetId)).value?.hidden ??
            false);
    // Le drapeau propre au compte, pas une déduction tirée de la dernière
    // décision : c’est ce que lisent les règles, donc ce que les boutons
    // doivent refléter.
    final accountSuspended =
        entry.target == ReportTarget.user &&
        (ref.watch(reportedAccountProvider(entry.targetId)).value?.suspended ??
            false);
    final actions = ModerationPolicy.actionsFor(
      entry.target,
      reviewHidden: reviewHidden,
      accountSuspended: accountSuspended,
    );

    return FrostedBar(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.md,
        AppSpacing.gutter,
        MediaQuery.paddingOf(context).bottom + AppSpacing.md,
      ),
      child: Row(
        children: [
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppButton(
                label: actions[i].label,
                variant: actions[i].destructive
                    ? AppButtonVariant.danger
                    : actions[i] == ModerationAction.dismiss
                    ? AppButtonVariant.secondary
                    : AppButtonVariant.primary,
                size: AppButtonSize.medium,
                onPressed: () => showModerationDecisionSheet(
                  context,
                  entry: entry,
                  action: actions[i],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
