import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/config/app_config.dart';
import 'package:eventhub/core/extensions/context_x.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/utils/date_formats.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/organizer/application/organizer_providers.dart';
import 'package:eventhub/features/organizer/domain/organizer_insights.dart';
import 'package:eventhub/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// "Alertes" — what moved on the organizer's events.
///
/// Two blocks with two different jobs. *À surveiller* is a to-do list
/// computed from the current state (an event starting tomorrow, the last two
/// seats); it disappears on its own when the situation resolves. *Activité*
/// is a journal — bookings and cancellations, grouped by day like a bank
/// statement, because "who signed up since yesterday" is read by day.
///
/// No "unread" state: that needs a per-device read marker, which belongs to
/// the push-notification work (ROADMAP F-02), not to a derived feed.
class OrganizerAlertsScreen extends ConsumerWidget {
  const OrganizerAlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activity = ref.watch(organizerActivityProvider);
    final watchlist = ref.watch(organizerWatchlistProvider).value ?? const [];
    final now = ref.watch(clockProvider)();

    return AppScaffold(
      constrainWidth: false,
      dense: true,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: ScreenHeader(
                eyebrow: AppStrings.organizer,
                title: AppStrings.alertsTitle,
                subtitle: AppStrings.alertsSubtitle,
              ),
            ),
            AsyncValueWidget(
              value: activity,
              sliver: true,
              onRetry: () => ref.invalidate(organizerReservationsProvider),
              isEmpty: (items) => items.isEmpty && watchlist.isEmpty,
              loading: SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.gutter,
                ),
                sliver: SliverList.separated(
                  itemCount: 5,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (_, __) =>
                      const Skeleton(height: 60, radius: AppRadius.button),
                ),
              ),
              empty: const SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyStateView(
                  icon: Icons.notifications_none_rounded,
                  title: AppStrings.noActivityTitle,
                  message: AppStrings.noActivity,
                ),
              ),
              data: (items) => SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.gutter,
                ),
                sliver: SliverList.list(
                  children: [
                    if (watchlist.isNotEmpty) ...[
                      const SectionLabel(AppStrings.watchlist),
                      const SizedBox(height: AppSpacing.md),
                      _Watchlist(alerts: watchlist, now: now),
                      const SizedBox(height: AppSpacing.xxxl),
                    ],
                    if (items.isNotEmpty) ...[
                      const SectionLabel(AppStrings.activity),
                      ..._journal(items, now),
                    ],
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: AppSizes.navBarInset),
            ),
          ],
        ),
      ),
    );
  }

  /// Rows interleaved with a day heading each time the calendar day changes.
  static List<Widget> _journal(List<OrganizerAlert> items, DateTime now) {
    final widgets = <Widget>[];
    DateTime? day;
    for (final item in items) {
      final itemDay = item.at.startOfDay;
      if (itemDay != day) {
        day = itemDay;
        widgets.add(_DayHeading(label: _dayLabel(itemDay, now)));
      }
      widgets.add(_ActivityRow(alert: item));
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

/// One bordered block, a coloured rule on the left of each row carrying the
/// reason. The rule, not a filled card, is what makes three different tones
/// sit together without turning the list into a traffic light.
class _Watchlist extends StatelessWidget {
  const _Watchlist({required this.alerts, required this.now});

  final List<OrganizerAlert> alerts;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: AppRadius.brButton,
        border: Border.all(color: t.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < alerts.length; i++) ...[
            if (i > 0) Divider(height: 1, color: t.borderSubtle),
            _WatchRow(alert: alerts[i], now: now),
          ],
        ],
      ),
    );
  }
}

class _WatchRow extends StatelessWidget {
  const _WatchRow({required this.alert, required this.now});

  final OrganizerAlert alert;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = context.textTheme;
    final seats = alert.seatsLeft ?? 0;

    final (tone, icon, headline) = switch (alert.kind) {
      AlertKind.startingSoon => (
        AppTone.info,
        Icons.schedule_rounded,
        _startsIn(alert.at.difference(now)),
      ),
      AlertKind.lastSeats => (
        AppTone.warning,
        Icons.local_fire_department_rounded,
        'Plus que $seats place${seats > 1 ? 's' : ''}',
      ),
      AlertKind.soldOut => (AppTone.success, Icons.verified_rounded, 'Complet'),
      AlertKind.booking ||
      AlertKind.cancellation => (AppTone.neutral, Icons.circle, ''),
    };
    final colors = t.resolve(tone);

    return InkWell(
      onTap: () =>
          context.push(AppRoutes.organizerEventParticipantsPath(alert.eventId)),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 3, color: colors.solid),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                ),
                child: Row(
                  children: [
                    Icon(icon, size: 18, color: colors.fg),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            headline,
                            style: text.titleSmall?.copyWith(color: colors.fg),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            '${alert.eventTitle} · '
                            '${AppDateFormats.dayMonthTime(alert.at)}',
                            style: text.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: t.textTertiary),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _startsIn(Duration d) {
    if (d.inMinutes < 60) return 'Commence dans moins d’une heure';
    return 'Commence dans ${d.inHours} h';
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

/// "Hanta Ravelo a réservé" — sentence first, because that is how the
/// organizer will repeat it to someone else.
class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.alert});

  final OrganizerAlert alert;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = context.textTheme;
    final cancelled = alert.kind == AlertKind.cancellation;
    final name = alert.personName ?? '';

    return InkWell(
      onTap: () =>
          context.push(AppRoutes.organizerEventParticipantsPath(alert.eventId)),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: t.borderSubtle)),
        ),
        child: Row(
          children: [
            Opacity(
              opacity: cancelled ? 0.5 : 1,
              child: AppAvatar(name: name, size: 36),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: name, style: text.titleSmall),
                        TextSpan(
                          text: cancelled ? ' a annulé' : ' a réservé',
                          style: text.bodyMedium?.copyWith(
                            color: cancelled ? t.danger.fg : t.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    alert.eventTitle,
                    style: text.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              AppDateFormats.time(alert.at),
              style: text.labelSmall?.copyWith(
                letterSpacing: 0,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
