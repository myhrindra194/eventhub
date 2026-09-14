import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/extensions/context_x.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/organizers/application/organizer_directory_providers.dart';
import 'package:eventhub/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// "Organisateurs suivis" — one ruled list, most recent first.
///
/// Each row watches the public profile by id, so a deleted organizer stays
/// visible (labelled) with the way to remove it instead of vanishing
/// silently from a list the user built.
class FollowingScreen extends ConsumerWidget {
  const FollowingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = ref.watch(followingIdsProvider);

    return AppScaffold(
      dense: true,
      appBar: AppBar(title: const Text(AppStrings.followingTitle)),
      body: AsyncValueWidget(
        value: ids,
        onRetry: () => ref.invalidate(followingIdsProvider),
        isEmpty: (list) => list.isEmpty,
        empty: const EmptyStateView(
          icon: Icons.person_add_alt_outlined,
          title: AppStrings.noFollowingTitle,
          message: AppStrings.noFollowing,
        ),
        data: (list) => ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.lg,
            AppSpacing.gutter,
            AppSpacing.huge,
          ),
          children: [
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: context.tokens.surface,
                borderRadius: AppRadius.brButton,
                border: Border.all(color: context.tokens.border),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < list.length; i++) ...[
                    if (i > 0)
                      Divider(height: 1, color: context.tokens.borderSubtle),
                    _FollowingRow(key: ValueKey(list[i]), organizerId: list[i]),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FollowingRow extends ConsumerWidget {
  const _FollowingRow({required this.organizerId, super.key});

  final String organizerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final text = context.textTheme;
    final profile = ref.watch(organizerProfileProvider(organizerId));

    return profile.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Skeleton(height: 40, radius: AppRadius.button),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (p) {
        if (p == null) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Icon(Icons.person_off_outlined, color: t.textTertiary),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    AppStrings.deletedOrganizer,
                    style: text.titleSmall?.copyWith(color: t.textSecondary),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final result = await ref
                        .read(followControllerProvider.notifier)
                        .toggle(organizerId);
                    if (result case Err(:final failure) when context.mounted) {
                      context.showFailure(failure);
                    }
                  },
                  style: TextButton.styleFrom(
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.brButton,
                    ),
                  ),
                  child: const Text('Retirer'),
                ),
              ],
            ),
          );
        }

        final rating = p.averageRating;
        final facts = [
          '${p.followerCount} ${AppStrings.followersLabel(p.followerCount)}',
          '${p.eventCount} ${AppStrings.eventsLabel(p.eventCount)}',
          if (rating != null)
            '${rating.toStringAsFixed(1).replaceAll('.', ',')} ★',
        ].join(' · ');

        return InkWell(
          onTap: () => context.push(AppRoutes.organizerPublicProfilePath(p.id)),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                AppAvatar(name: p.name, size: 42),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: text.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(facts, style: text.bodySmall, maxLines: 1),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: t.textTertiary),
              ],
            ),
          ),
        );
      },
    );
  }
}
