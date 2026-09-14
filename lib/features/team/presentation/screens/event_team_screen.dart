import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/extensions/context_x.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/auth/application/auth_providers.dart';
import 'package:eventhub/features/events/application/event_providers.dart';
import 'package:eventhub/features/events/domain/entities/event.dart';
import 'package:eventhub/features/events/domain/policies/event_policy.dart';
import 'package:eventhub/features/organizers/application/organizer_directory_providers.dart';
import 'package:eventhub/features/team/application/team_providers.dart';
import 'package:eventhub/features/team/domain/team.dart';
import 'package:eventhub/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Team of an event (F-16).
///
/// The owner sees an invitation field, the members and the pending
/// invitations, each removable. A co-organizer sees the same list read-only
/// and one action: leave. What a co-organizer can and cannot do is written
/// on the screen, because "co-organizer" means different things elsewhere.
class EventTeamScreen extends ConsumerStatefulWidget {
  const EventTeamScreen({required this.eventId, super.key});

  final String eventId;

  @override
  ConsumerState<EventTeamScreen> createState() => _EventTeamScreenState();
}

class _EventTeamScreenState extends ConsumerState<EventTeamScreen> {
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _invite() async {
    FocusScope.of(context).unfocus();
    final email = _email.text.trim();
    final result = await ref
        .read(teamControllerProvider.notifier)
        .invite(eventId: widget.eventId, email: email);
    if (!mounted) return;
    switch (result) {
      case Ok():
        _email.clear();
        setState(() {});
        context.showSuccess(AppStrings.invitationSent(email));
      case Err(:final failure):
        context.showFailure(failure);
    }
  }

  Future<void> _remove({
    required String userId,
    required String title,
    required String message,
    required String confirmLabel,
    required String done,
    bool leaving = false,
  }) async {
    final confirmed = await showConfirmSheet(
      context,
      icon: leaving ? Icons.logout_rounded : Icons.person_remove_outlined,
      title: title,
      message: message,
      confirmLabel: confirmLabel,
    );
    if (!confirmed || !mounted) return;
    final result = await ref
        .read(teamControllerProvider.notifier)
        .remove(eventId: widget.eventId, userId: userId);
    if (!mounted) return;
    switch (result) {
      case Ok():
        context.showSuccess(done);
        if (leaving) context.go(AppRoutes.organizerEvents);
      case Err(:final failure):
        context.showFailure(failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = ref.watch(eventByIdProvider(widget.eventId));

    return AppScaffold(
      dense: true,
      appBar: AppBar(title: const Text(AppStrings.teamTitle)),
      body: AsyncValueWidget(
        value: event,
        onRetry: () => ref.invalidate(eventByIdProvider(widget.eventId)),
        isEmpty: (e) => e == null,
        empty: const EmptyStateView(
          icon: Icons.link_off_rounded,
          message: AppStrings.eventNotFound,
        ),
        data: (e) => _body(context, e!),
      ),
    );
  }

  Widget _body(BuildContext context, Event event) {
    final t = context.tokens;
    final text = context.textTheme;
    final user = ref.watch(currentUserProvider);
    final isOwner = user != null && event.isOwnedBy(user.id);
    final pending =
        ref.watch(eventPendingInvitationsProvider(event.id)).value ??
        const <StaffInvitation>[];
    final busy = ref.watch(teamControllerProvider).isLoading;
    final seats = EventPolicy.maxStaff - event.staffIds.length - pending.length;

    Widget ruled(List<Widget> rows) => Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: AppRadius.brButton,
        border: Border.all(color: t.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) Divider(height: 1, color: t.borderSubtle),
            rows[i],
          ],
        ],
      ),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.lg,
        AppSpacing.gutter,
        AppSpacing.huge,
      ),
      children: [
        Text(event.title, style: text.headlineSmall),
        const SizedBox(height: AppSpacing.sm),
        Text(AppStrings.teamLead, style: text.bodySmall?.copyWith(height: 1.5)),
        if (isOwner) ...[
          const SizedBox(height: AppSpacing.xl),
          const SectionLabel(AppStrings.inviteCoOrganizer),
          const SizedBox(height: AppSpacing.md),
          FieldGroup(
            children: [
              FieldRow(
                icon: Icons.alternate_email_rounded,
                controller: _email,
                hint: AppStrings.coOrganizerEmailHint,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.send,
                enabled: !busy && seats > 0,
                onChanged: (_) => setState(() {}),
                onFieldSubmitted: (_) => _invite(),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            seats > 0 ? AppStrings.teamSeatsLeft(seats) : AppStrings.teamFull,
            style: text.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton.primary(
            label: AppStrings.sendInvitation,
            icon: Icons.person_add_alt_1_rounded,
            elevated: false,
            isLoading: busy,
            loadingLabel: AppStrings.decisionSending,
            onPressed: _email.text.trim().isEmpty || busy || seats <= 0
                ? null
                : _invite,
          ),
        ],
        const SizedBox(height: AppSpacing.xxl),
        const SectionLabel(AppStrings.teamMembers),
        const SizedBox(height: AppSpacing.md),
        ruled([
          _MemberRow(
            userId: event.organizerId,
            fallbackName: event.organizerName,
            badge: AppStrings.teamOwner,
          ),
          for (final id in event.staffIds)
            _MemberRow(
              userId: id,
              badge: id == user?.id ? AppStrings.you : null,
              action: isOwner
                  ? TextButton(
                      onPressed: busy
                          ? null
                          : () => _remove(
                              userId: id,
                              title: AppStrings.removeMemberTitle,
                              message: AppStrings.removeMemberMessage,
                              confirmLabel: AppStrings.removeMember,
                              done: AppStrings.memberRemoved,
                            ),
                      style: TextButton.styleFrom(
                        foregroundColor: t.danger.fg,
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppRadius.brButton,
                        ),
                      ),
                      child: const Text(AppStrings.removeMember),
                    )
                  : null,
            ),
        ]),
        if (pending.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xxl),
          const SectionLabel(AppStrings.pendingInvitations),
          const SizedBox(height: AppSpacing.md),
          ruled([
            for (final invitation in pending)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 20,
                      color: t.textTertiary,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            invitation.name.isEmpty
                                ? invitation.email
                                : invitation.name,
                            style: text.titleSmall,
                          ),
                          Text(invitation.email, style: text.bodySmall),
                        ],
                      ),
                    ),
                    if (isOwner)
                      TextButton(
                        onPressed: busy
                            ? null
                            : () => _remove(
                                userId: invitation.userId,
                                title: AppStrings.cancelInvitationTitle,
                                message: AppStrings.cancelInvitationMessage,
                                confirmLabel: AppStrings.cancelInvitation,
                                done: AppStrings.invitationCancelled,
                              ),
                        style: TextButton.styleFrom(
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppRadius.brButton,
                          ),
                        ),
                        child: const Text(AppStrings.cancelInvitation),
                      ),
                  ],
                ),
              ),
          ]),
        ],
        if (!isOwner && user != null && event.isStaff(user.id)) ...[
          const SizedBox(height: AppSpacing.xxl),
          AppButton.secondary(
            label: AppStrings.leaveTeam,
            icon: Icons.logout_rounded,
            elevated: false,
            onPressed: busy
                ? null
                : () => _remove(
                    userId: user.id,
                    title: AppStrings.leaveTeamTitle,
                    message: AppStrings.leaveTeamMessage,
                    confirmLabel: AppStrings.leaveTeam,
                    done: AppStrings.teamLeft,
                    leaving: true,
                  ),
          ),
        ],
      ],
    );
  }
}

/// One member: their public organizer profile gives the name.
class _MemberRow extends ConsumerWidget {
  const _MemberRow({
    required this.userId,
    this.fallbackName,
    this.badge,
    this.action,
  });

  final String userId;
  final String? fallbackName;
  final String? badge;
  final Widget? action;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = context.textTheme;
    final profile = ref.watch(organizerProfileProvider(userId)).value;
    final name = profile?.name ?? fallbackName ?? AppStrings.deletedOrganizer;

    return InkWell(
      onTap: () => context.push(AppRoutes.organizerPublicProfilePath(userId)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
        ),
        child: Row(
          children: [
            AppAvatar(name: name, size: 36),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                name,
                style: text.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (badge != null)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: AppBadge(
                  label: badge!,
                  tone: AppTone.neutral,
                  dense: true,
                ),
              ),
            ?action,
          ],
        ),
      ),
    );
  }
}
