import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/features/notifications/application/notification_providers.dart';
import 'package:eventhub/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Square 6 px bell with an unread dot, opening the notification history.
///
/// A dot, not a number: the count of unread notifications is not an
/// actionable figure, the fact that there is something new is.
class NotificationBellButton extends ConsumerWidget {
  const NotificationBellButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final unread = ref.watch(unreadNotificationCountProvider);

    return Tooltip(
      message: AppStrings.notificationsTitle,
      child: Semantics(
        button: true,
        label: unread > 0
            ? '${AppStrings.notificationsTitle}, $unread non lue'
                  '${unread > 1 ? 's' : ''}'
            : AppStrings.notificationsTitle,
        child: Material(
          color: t.surface,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.brButton,
            side: BorderSide(color: t.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => context.push(AppRoutes.notificationsCenter),
            child: SizedBox.square(
              dimension: 42,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    unread > 0
                        ? Icons.notifications_rounded
                        : Icons.notifications_none_rounded,
                    size: 20,
                    color: t.textSecondary,
                  ),
                  if (unread > 0)
                    Positioned(
                      top: 9,
                      right: 10,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: t.accent,
                          shape: BoxShape.circle,
                          border: Border.all(color: t.surface, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
