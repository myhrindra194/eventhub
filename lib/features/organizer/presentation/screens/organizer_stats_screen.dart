import 'dart:math' as math;

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

/// "Statistiques" — how the organizer's events are doing.
///
/// Read top to bottom, from the answer to the detail: one hero figure (the
/// global fill rate — the only number that says "ça marche ?"), four
/// secondary figures in a hairline grid, the booking rhythm over two weeks,
/// then each upcoming event ranked by how full it is.
///
/// The chart follows the data-viz rules of the design system: a single
/// series in a single hue, thin columns with a 2 px gap, direct labels only
/// on the peak and on the selected day, and a table view carrying exactly
/// the same values for anyone who cannot read the chart.
class OrganizerStatsScreen extends ConsumerWidget {
  const OrganizerStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(organizerStatsProvider);
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
                title: AppStrings.statsTitle,
                subtitle: AppStrings.statsSubtitle,
              ),
            ),
            AsyncValueWidget(
              value: stats,
              sliver: true,
              onRetry: () => ref.invalidate(organizerReservationsProvider),
              isEmpty: (s) => s.eventCount == 0,
              loading: const SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
                sliver: SliverList(
                  delegate: SliverChildListDelegate.fixed([
                    Skeleton(height: 110, radius: AppRadius.button),
                    SizedBox(height: AppSpacing.lg),
                    Skeleton(height: 150, radius: AppRadius.button),
                    SizedBox(height: AppSpacing.lg),
                    Skeleton(height: 200, radius: AppRadius.button),
                  ]),
                ),
              ),
              empty: SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyStateView(
                  icon: Icons.insights_rounded,
                  title: 'Pas encore de chiffres',
                  message:
                      'Publiez un premier événement : sa jauge et ses '
                      'réservations apparaîtront ici en direct.',
                  action: AppButton.primary(
                    label: AppStrings.createFirstEvent,
                    icon: Icons.add_rounded,
                    expand: false,
                    onPressed: () => context.push(AppRoutes.organizerEventNew),
                  ),
                ),
              ),
              data: (s) => SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.gutter,
                ),
                sliver: SliverList.list(
                  children: [
                    _Headline(stats: s),
                    const SizedBox(height: AppSpacing.xxl),
                    _Figures(stats: s),
                    const SizedBox(height: AppSpacing.xxxl),
                    _BookingsChart(daily: s.dailyBookings, now: now),
                    const SizedBox(height: AppSpacing.xxxl),
                    const SectionLabel('Événements à venir'),
                    const SizedBox(height: AppSpacing.md),
                    if (s.ranking.isEmpty)
                      Text(
                        'Aucun événement à venir. Les événements passés restent '
                        'comptés dans les totaux ci-dessus.',
                        style: context.textTheme.bodySmall,
                      )
                    else
                      _Ranking(items: s.ranking),
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
}

String _percent(double ratio) => '${(ratio * 100).round()} %';

/// The hero figure. Exactly one per view, proportional digits.
class _Headline extends StatelessWidget {
  const _Headline({required this.stats});

  final OrganizerStats stats;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Remplissage global', style: text.bodyMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(
          _percent(stats.fillRate),
          style: text.displayMedium?.copyWith(
            fontSize: 56,
            height: 1,
            letterSpacing: -1.5,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '${stats.booked} places réservées sur ${stats.capacity}, '
          '${stats.eventCount} événement${stats.eventCount > 1 ? 's' : ''}',
          style: text.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),
        CapacityMeter(
          available: stats.capacity - stats.booked,
          capacity: stats.capacity,
          showCaption: false,
          height: 6,
        ),
      ],
    );
  }
}

/// Four secondary figures in one bordered grid, split by hairlines — a
/// table, not four floating cards.
class _Figures extends StatelessWidget {
  const _Figures({required this.stats});

  final OrganizerStats stats;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final s = stats;

    Widget row(Widget a, Widget b) => IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: a),
          VerticalDivider(width: 1, color: t.borderSubtle),
          Expanded(child: b),
        ],
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: AppRadius.brButton,
        border: Border.all(color: t.border),
      ),
      child: Column(
        children: [
          row(
            _Figure(label: 'Réservations', value: '${s.booked}'),
            _Figure(
              label: '7 derniers jours',
              value: '${s.bookingsLast7Days}',
              note: 'nouvelles réservations',
            ),
          ),
          Divider(height: 1, color: t.borderSubtle),
          row(
            _Figure(
              label: 'Annulations',
              value: '${s.cancellations}',
              note: '${_percent(s.cancellationRate)} des réservations',
            ),
            _Figure(
              label: 'Complets',
              value: '${s.soldOutCount}',
              note: 'sur ${s.upcomingCount} à venir',
            ),
          ),
        ],
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.label, required this.value, this.note});

  final String label;
  final String value;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: text.bodySmall),
          const SizedBox(height: AppSpacing.xs),
          Text(value, style: text.headlineMedium),
          if (note != null)
            Text(
              note!,
              style: text.labelSmall?.copyWith(
                letterSpacing: 0,
                color: context.tokens.textTertiary,
              ),
            ),
        ],
      ),
    );
  }
}

/// Bookings per day over [OrganizerStats.window] days.
class _BookingsChart extends StatefulWidget {
  const _BookingsChart({required this.daily, required this.now});

  final List<int> daily;
  final DateTime now;

  @override
  State<_BookingsChart> createState() => _BookingsChartState();
}

class _BookingsChartState extends State<_BookingsChart> {
  static const _plotHeight = 120.0;

  /// Today is selected by default: it is the day the organizer asks about.
  late int _selected = widget.daily.length - 1;
  bool _asTable = false;

  DateTime _dayAt(int index) {
    final back = widget.daily.length - 1 - index;
    return DateTime(widget.now.year, widget.now.month, widget.now.day - back);
  }

  String _dayLabel(int index) => index == widget.daily.length - 1
      ? "Aujourd'hui"
      : AppDateFormats.dayMonth(_dayAt(index));

  String _count(int n) => '$n réservation${n > 1 ? 's' : ''}';

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = context.textTheme;
    final daily = widget.daily;
    final peak = daily.fold(0, math.max);
    final peakIndex = daily.indexOf(peak);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Réservations sur ${daily.length} jours',
                    style: text.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    _asTable
                        ? 'Une ligne par jour, du plus récent au plus ancien'
                        : '${_dayLabel(_selected)} · ${_count(daily[_selected])}',
                    style: text.bodySmall,
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: () => setState(() => _asTable = !_asTable),
              icon: Icon(
                _asTable ? Icons.bar_chart_rounded : Icons.table_rows_outlined,
                size: 16,
              ),
              label: Text(_asTable ? 'Graphique' : 'Tableau'),
              style: TextButton.styleFrom(
                foregroundColor: t.textSecondary,
                visualDensity: VisualDensity.compact,
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.brButton,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        if (_asTable)
          _table(context)
        else
          Semantics(
            label:
                'Histogramme des réservations par jour. '
                'Pic : ${_count(peak)} le ${_dayLabel(peakIndex)}. '
                "Aujourd'hui : ${_count(daily.last)}.",
            child: _chart(context, peak, peakIndex),
          ),
      ],
    );
  }

  Widget _chart(BuildContext context, int peak, int peakIndex) {
    final t = context.tokens;
    final text = context.textTheme;
    final daily = widget.daily;
    final labelStyle = text.labelSmall?.copyWith(
      letterSpacing: 0,
      color: t.textSecondary,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Column(
      children: [
        SizedBox(
          // Plot plus the band reserved for the value label on a cap, so a
          // label on the tallest column is never clipped.
          height: _plotHeight + 20,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < daily.length; i++)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _selected = i),
                    // The whole slot is the hit target, not the column.
                    child: LayoutBuilder(
                      builder: (context, box) {
                        final value = daily[i];
                        final height = peak == 0
                            ? 0.0
                            : value / peak * _plotHeight;
                        final selected = i == _selected;
                        final labelled =
                            value > 0 && (selected || i == peakIndex);
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (labelled) ...[
                              Text('$value', style: labelStyle),
                              const SizedBox(height: AppSpacing.xxs),
                            ],
                            AnimatedContainer(
                              duration: AppMotion.short,
                              curve: AppMotion.standard,
                              // ≤ 24 px, and the slot keeps a 2 px surface gap.
                              width: math.min(24, box.maxWidth - 2),
                              height: height,
                              decoration: BoxDecoration(
                                color: selected
                                    ? t.brand
                                    : t.brand.withValues(alpha: 0.42),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
        Container(height: 1, color: t.border),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Text(AppDateFormats.dayMonth(_dayAt(0)), style: labelStyle),
            const Spacer(),
            Text("Aujourd'hui", style: labelStyle),
          ],
        ),
      ],
    );
  }

  Widget _table(BuildContext context) {
    final t = context.tokens;
    final text = context.textTheme;
    final daily = widget.daily;

    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.brButton,
        border: Border.all(color: t.border),
      ),
      child: Column(
        children: [
          for (var i = daily.length - 1; i >= 0; i--) ...[
            if (i < daily.length - 1) Divider(height: 1, color: t.borderSubtle),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(child: Text(_dayLabel(i), style: text.bodyMedium)),
                  Text(
                    '${daily[i]}',
                    style: text.titleSmall?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Upcoming events, fullest first. The ranking is the point: the event at
/// the bottom is the one that needs promotion.
class _Ranking extends StatelessWidget {
  const _Ranking({required this.items});

  final List<EventPerformance> items;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = context.textTheme;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: AppRadius.brButton,
        border: Border.all(color: t.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) Divider(height: 1, color: t.borderSubtle),
            InkWell(
              onTap: () => context.push(
                AppRoutes.organizerEventParticipantsPath(items[i].event.id),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                items[i].event.title,
                                style: text.titleSmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                AppDateFormats.dayMonthTime(
                                  items[i].event.startsAt,
                                ),
                                style: text.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Text(
                          _percent(items[i].event.fillRate),
                          style: text.titleSmall?.copyWith(
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    CapacityMeter(
                      available: items[i].event.availablePlaces,
                      capacity: items[i].event.capacity,
                      height: 4,
                      caption: items[i].cancellations == 0
                          ? null
                          : '${items[i].cancellations} annulation'
                                '${items[i].cancellations > 1 ? 's' : ''}',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
