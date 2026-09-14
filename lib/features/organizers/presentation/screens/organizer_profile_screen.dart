import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/config/app_config.dart';
import 'package:eventhub/core/extensions/context_x.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/utils/date_formats.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/auth/application/auth_providers.dart';
import 'package:eventhub/features/events/application/event_providers.dart';
import 'package:eventhub/features/events/domain/entities/event.dart';
import 'package:eventhub/features/events/presentation/widgets/event_card.dart';
import 'package:eventhub/features/moderation/domain/report.dart';
import 'package:eventhub/features/moderation/presentation/widgets/report_sheet.dart';
import 'package:eventhub/features/organizers/application/organizer_directory_providers.dart';
import 'package:eventhub/features/organizers/domain/organizer_profile.dart';
import 'package:eventhub/features/organizers/presentation/widgets/follow_button.dart';
import 'package:eventhub/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Public profile of an organizer (F-10).
///
/// Laid out like a letterhead rather than a social card: identity and bio
/// read first, then three facts in a ruled table (events, followers, rating)
/// — the numbers someone weighs before trusting an organizer — then the one
/// action, then their dates. Upcoming events come before past ones because
/// they are the reason to follow.
///
/// Opened by both roles. On one's own profile the follow button becomes
/// "Modifier ma présentation" and the report action disappears.
class OrganizerProfileScreen extends ConsumerWidget {
  const OrganizerProfileScreen({required this.organizerId, super.key});

  final String organizerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(organizerProfileProvider(organizerId));
    final user = ref.watch(currentUserProvider);
    final isSelf = user?.id == organizerId;

    return AppScaffold(
      dense: true,
      appBar: AppBar(
        title: const Text(AppStrings.organizerProfileTitle),
        actions: [
          if (user != null && !isSelf && profile.value != null)
            IconButton(
              tooltip: AppStrings.reportAction,
              icon: const Icon(Icons.flag_outlined),
              onPressed: () => showReportSheet(
                context,
                target: ReportTarget.user,
                targetId: organizerId,
                subject: profile.value!.name,
              ),
            ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: AsyncValueWidget(
        value: profile,
        onRetry: () => ref.invalidate(organizerProfileProvider(organizerId)),
        isEmpty: (p) => p == null,
        empty: const EmptyStateView(
          icon: Icons.person_off_outlined,
          title: AppStrings.organizerNotFoundTitle,
          message: AppStrings.organizerNotFound,
        ),
        data: (p) => _Body(profile: p!, isSelf: isSelf),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.profile, required this.isSelf});

  final OrganizerProfile profile;
  final bool isSelf;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = context.textTheme;
    final t = context.tokens;
    final now = ref.watch(clockProvider)();
    final user = ref.watch(currentUserProvider);
    final following = ref.watch(isFollowingProvider(profile.id));
    final events = ref.watch(organizerEventsProvider(profile.id));

    final all = events.value ?? const <Event>[];
    final upcoming = all.where((e) => !e.hasStarted(now)).toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    final past = all.where((e) => e.hasStarted(now)).take(10).toList();

    // A participant opens the event; the organizer opens their guest list;
    // another organizer has no screen for someone else's event.
    VoidCallback? openerFor(Event e) {
      if (user?.isParticipant ?? false) {
        return () => context.push(AppRoutes.eventDetailPath(e.id));
      }
      if (isSelf) {
        return () =>
            context.push(AppRoutes.organizerEventParticipantsPath(e.id));
      }
      return null;
    }

    Widget tile(Event e) {
      final open = openerFor(e);
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: IgnorePointer(
          ignoring: open == null,
          child: EventResultTile(event: e, onTap: open ?? () {}),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.lg,
        AppSpacing.gutter,
        AppSpacing.huge,
      ),
      children: [
        _Header(profile: profile),
        const SizedBox(height: AppSpacing.xl),
        _Facts(profile: profile),
        const SizedBox(height: AppSpacing.xl),
        if (isSelf)
          AppButton.secondary(
            label: AppStrings.editPublicProfile,
            icon: Icons.edit_outlined,
            size: AppButtonSize.medium,
            elevated: false,
            onPressed: () => context.push(AppRoutes.editProfile),
          )
        else ...[
          FollowButton(organizerId: profile.id),
          const SizedBox(height: AppSpacing.sm),
          Text(
            following ? AppStrings.followingHint : AppStrings.followHint,
            style: text.bodySmall?.copyWith(height: 1.45),
          ),
        ],
        const SizedBox(height: AppSpacing.xxxl),
        Row(
          children: [
            const SectionLabel(AppStrings.upcomingEventsTitle),
            const Spacer(),
            if (upcoming.isNotEmpty)
              Text('${upcoming.length}', style: text.labelMedium),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (events.isLoading && !events.hasValue)
          const Skeleton(height: 96, radius: AppRadius.button)
        else if (upcoming.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: AppRadius.brButton,
              border: Border.all(color: t.borderSubtle),
            ),
            child: Text(
              isSelf
                  ? AppStrings.noUpcomingForSelf
                  : AppStrings.noUpcomingForOrganizer,
              style: text.bodyMedium?.copyWith(color: t.textSecondary),
            ),
          )
        else
          for (final e in upcoming) tile(e),
        if (past.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xxl),
          const SectionLabel(AppStrings.pastEventsTitle),
          const SizedBox(height: AppSpacing.md),
          for (final e in past) Opacity(opacity: 0.72, child: tile(e)),
        ],
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.profile});

  final OrganizerProfile profile;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = context.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AppAvatar(name: profile.name, size: 64),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.name,
                    style: text.headlineMedium?.copyWith(height: 1.15),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (profile.memberSince != null) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      AppStrings.organizerSince(
                        AppDateFormats.shortDate(profile.memberSince!),
                      ),
                      style: text.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          profile.hasBio ? profile.bio : AppStrings.organizerNoBio,
          style: text.bodyLarge?.copyWith(
            color: profile.hasBio ? t.textSecondary : t.textTertiary,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

/// Three facts, one ruled row: value large, unit small beneath.
class _Facts extends StatelessWidget {
  const _Facts({required this.profile});

  final OrganizerProfile profile;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final rating = profile.averageRating;

    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: AppRadius.brButton,
        border: Border.all(color: t.border),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _Fact(
                value: '${profile.eventCount}',
                label: AppStrings.eventsLabel(profile.eventCount),
              ),
            ),
            VerticalDivider(width: 1, color: t.borderSubtle),
            Expanded(
              child: _Fact(
                value: '${profile.followerCount}',
                label: AppStrings.followersLabel(profile.followerCount),
              ),
            ),
            VerticalDivider(width: 1, color: t.borderSubtle),
            Expanded(
              child: _Fact(
                value: rating == null
                    ? '—'
                    : rating.toStringAsFixed(1).replaceAll('.', ','),
                label: rating == null
                    ? AppStrings.noRatingYet
                    : AppStrings.ratingCountLabel(profile.ratingCount),
                icon: rating == null ? null : Icons.star_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.value, required this.label, this.icon});

  final String value;
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = context.textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                value,
                style: text.headlineSmall?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (icon != null) ...[
                const SizedBox(width: AppSpacing.xxs),
                Icon(icon, size: 16, color: t.warning.solid),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            label,
            style: text.labelSmall?.copyWith(
              letterSpacing: 0,
              color: t.textTertiary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
