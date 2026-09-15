import 'dart:async';

import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/config/app_config.dart';
import 'package:eventhub/core/extensions/context_x.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/core/utils/date_formats.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/notifications/application/notification_providers.dart';
import 'package:eventhub/features/notifications/application/notification_route.dart';
import 'package:eventhub/features/notifications/domain/app_notification.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Notification history — what the pushes said, after the push is gone.
///
/// Grouped by day, unread entries marked by a dot and a heavier title. A tap
/// marks the entry read and opens what it is about (same routing as the
/// system notification); a swipe deletes it. Entries expire after 30 days
/// server-side (TTL), which the empty state says so nobody hunts for an old
/// one.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(notificationFeedProvider);
    final unread = ref.watch(unreadNotificationCountProvider);
    final now = ref.watch(clockProvider)();

    return AppScaffold(
      dense: true,
      appBar: AppBar(
        title: const Text(AppStrings.notificationsTitle),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: () async {
                final result = await ref
                    .read(notificationFeedControllerProvider.notifier)
                    .markAllRead();
                if (result case Err(:final failure) when context.mounted) {
                  context.showFailure(failure);
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: context.tokens.brand,
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.brButton,
                ),
              ),
              child: const Text(AppStrings.markAllRead),
            ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: AsyncValueWidget(
        value: feed,
        onRetry: () => ref.invalidate(notificationFeedProvider),
        isEmpty: (list) => list.isEmpty,
        empty: const EmptyStateView(
          icon: Icons.notifications_off_outlined,
          title: AppStrings.noNotificationsTitle,
          message: AppStrings.noNotifications,
        ),
        data: (list) => ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.sm,
            AppSpacing.gutter,
            AppSpacing.huge,
          ),
          children: _grouped(list, now),
        ),
      ),
    );
  }

  static List<Widget> _grouped(List<AppNotification> items, DateTime now) {
    final widgets = <Widget>[];
    DateTime? day;
    for (final item in items) {
      final itemDay = item.createdAt.startOfDay;
      if (itemDay != day) {
        day = itemDay;
        widgets.add(_DayHeading(label: _dayLabel(itemDay, now)));
      }
      widgets.add(_NotificationRow(key: ValueKey(item.id), notification: item));
    }
    return widgets;
  }

  static String _dayLabel(DateTime day, DateTime now) {
    final today = now.startOfDay;
    if (day == today) return "Aujourd'hui";
    if (day == today.subtract(const Duration(days: 1))) return 'Hier';
    return AppDateFormats.weekdayDate(day);
  }
}

class _DayHeading extends StatelessWidget {
  const _DayHeading({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.xs),
    child: Text(
      label,
      style: context.textTheme.labelMedium?.copyWith(
        color: context.tokens.textTertiary,
      ),
    ),
  );
}

class _NotificationRow extends ConsumerWidget {
  const _NotificationRow({required this.notification, super.key});

  final AppNotification notification;

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(notificationFeedControllerProvider.notifier);
    unawaited(controller.markRead(notification));
    final location = NotificationRoute.locationFor(notification.routeData);
    if (location != null && context.mounted) {
      unawaited(context.push(location));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final text = context.textTheme;
    final n = notification;

    final (icon, tone) = switch (n.type) {
      NotificationRoute.booking => (
        Icons.event_available_rounded,
        AppTone.success,
      ),
      NotificationRoute.cancellation => (
        Icons.event_busy_rounded,
        AppTone.danger,
      ),
      NotificationRoute.reminder => (Icons.alarm_rounded, AppTone.brand),
      NotificationRoute.waitlist => (
        Icons.hourglass_top_rounded,
        AppTone.warning,
      ),
      NotificationRoute.newEvent => (Icons.campaign_outlined, AppTone.info),
      NotificationRoute.eventRemoved => (
        Icons.event_busy_rounded,
        AppTone.danger,
      ),
      NotificationRoute.paymentConfirmed => (
        Icons.credit_score_rounded,
        AppTone.success,
      ),
      NotificationRoute.paymentRefunded => (
        Icons.currency_exchange_rounded,
        AppTone.info,
      ),
      NotificationRoute.staffInvite => (
        Icons.mail_outline_rounded,
        AppTone.info,
      ),
      NotificationRoute.staffJoined => (
        Icons.diversity_3_rounded,
        AppTone.success,
      ),
      NotificationRoute.staffRemoved => (
        Icons.person_remove_outlined,
        AppTone.neutral,
      ),
      NotificationRoute.reviewHidden => (
        Icons.visibility_off_outlined,
        AppTone.warning,
      ),
      NotificationRoute.welcome => (Icons.waving_hand_outlined, AppTone.brand),
      _ => (Icons.notifications_rounded, AppTone.neutral),
    };
    final colors = t.resolve(tone);

    return Dismissible(
      key: ValueKey('dismiss-${n.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        color: t.danger.bg,
        child: Icon(Icons.delete_outline_rounded, color: t.danger.fg),
      ),
      onDismissed: (_) async {
        final result = await ref
            .read(notificationFeedControllerProvider.notifier)
            .delete(n);
        if (!context.mounted) return;
        switch (result) {
          case Ok():
            context.showToast(AppStrings.notificationDeleted);
          case Err(:final failure):
            context.showFailure(failure);
        }
      },
      child: InkWell(
        onTap: () => _open(context, ref),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: t.borderSubtle)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colors.bg,
                  borderRadius: AppRadius.brButton,
                ),
                child: Icon(icon, size: 18, color: colors.fg),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      n.title,
                      style: text.titleSmall?.copyWith(
                        fontWeight: n.isRead
                            ? FontWeight.w500
                            : FontWeight.w700,
                        color: n.isRead ? t.textSecondary : t.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      n.body,
                      style: text.bodySmall?.copyWith(height: 1.4),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    AppDateFormats.time(n.createdAt),
                    style: text.labelSmall?.copyWith(
                      letterSpacing: 0,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  if (!n.isRead) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: t.brand,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
