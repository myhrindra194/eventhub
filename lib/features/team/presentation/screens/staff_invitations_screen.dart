import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/extensions/context_x.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/core/utils/date_formats.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/team/application/team_providers.dart';
import 'package:eventhub/features/team/domain/team.dart';
import 'package:eventhub/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Invitations to co-organize waiting for an answer (F-16).
class StaffInvitationsScreen extends ConsumerWidget {
  const StaffInvitationsScreen({super.key});

  Future<void> _respond(
    BuildContext context,
    WidgetRef ref,
    StaffInvitation invitation, {
    required bool accept,
  }) async {
    final result = await ref
        .read(teamControllerProvider.notifier)
        .respond(eventId: invitation.eventId, accept: accept);
    if (!context.mounted) return;
    switch (result) {
      case Ok():
        context.showSuccess(
          accept
              ? AppStrings.invitationAccepted(invitation.eventTitle)
              : AppStrings.invitationDeclined,
        );
        if (accept) {
          await context.push(
            AppRoutes.organizerEventParticipantsPath(invitation.eventId),
          );
        }
      case Err(:final failure):
        context.showFailure(failure);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invitations = ref.watch(myStaffInvitationsProvider);
    final busy = ref.watch(teamControllerProvider).isLoading;
    final t = context.tokens;
    final text = context.textTheme;

    return AppScaffold(
      dense: true,
      appBar: AppBar(title: const Text(AppStrings.invitationsTitle)),
      body: AsyncValueWidget(
        value: invitations,
        onRetry: () => ref.invalidate(myStaffInvitationsProvider),
        isEmpty: (list) => list.isEmpty,
        empty: const EmptyStateView(
          icon: Icons.mark_email_read_outlined,
          title: AppStrings.noInvitationsTitle,
          message: AppStrings.noInvitations,
        ),
        data: (list) => ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.lg,
            AppSpacing.gutter,
            AppSpacing.huge,
          ),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) {
            final invitation = list[index];
            return Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius: AppRadius.brButton,
                border: Border.all(color: t.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionLabel(AppStrings.invitedBy(invitation.invitedByName)),
                  const SizedBox(height: AppSpacing.sm),
                  Text(invitation.eventTitle, style: text.titleMedium),
                  if (invitation.eventStartsAt != null)
                    Text(
                      AppDateFormats.dayMonthTime(invitation.eventStartsAt!),
                      style: text.bodySmall,
                    ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    AppStrings.coOrganizerRights,
                    style: text.bodySmall?.copyWith(height: 1.45),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton.secondary(
                          label: AppStrings.decline,
                          size: AppButtonSize.medium,
                          elevated: false,
                          onPressed: busy
                              ? null
                              : () => _respond(
                                  context,
                                  ref,
                                  invitation,
                                  accept: false,
                                ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: AppButton.primary(
                          label: AppStrings.accept,
                          size: AppButtonSize.medium,
                          elevated: false,
                          onPressed: busy
                              ? null
                              : () => _respond(
                                  context,
                                  ref,
                                  invitation,
                                  accept: true,
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
