import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/extensions/context_x.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/utils/date_formats.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/admin/application/moderation_providers.dart';
import 'package:eventhub/features/admin/domain/moderation.dart';
import 'package:eventhub/features/moderation/domain/report.dart';
import 'package:eventhub/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// File de modération — une ligne par cible signalée.
///
/// Conçue pour le tri, pas pour la lecture : les plus signalées d’abord, le
/// motif et le compteur sur la ligne, une mention « masqué auto » là où le
/// seuil a déjà agi. Deux segments (à traiter / traités) et un filtre par
/// type ; la décision elle-même se prend sur l’écran du dossier, avec le
/// contenu et les signalements côte à côte.
class ModerationQueueScreen extends ConsumerStatefulWidget {
  const ModerationQueueScreen({super.key});

  @override
  ConsumerState<ModerationQueueScreen> createState() =>
      _ModerationQueueScreenState();
}

class _ModerationQueueScreenState extends ConsumerState<ModerationQueueScreen> {
  bool _open = true;
  ReportTarget? _filter;

  @override
  Widget build(BuildContext context) {
    final queue = ref.watch(moderationQueueProvider(open: _open));
    final openCount = ref.watch(openModerationCountProvider);

    return AppScaffold(
      dense: true,
      appBar: AppTopBar.subPage(
        title: AppStrings.moderationTitle,
        onBack: () => context.pop(),
        actions: [
          IconButton(
            tooltip: AppStrings.adminRolesTitle,
            icon: const Icon(Icons.admin_panel_settings_outlined),
            onPressed: () => context.push(AppRoutes.adminRoles),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              AppSpacing.md,
              AppSpacing.gutter,
              AppSpacing.sm,
            ),
            child: _Segments(
              open: _open,
              openCount: openCount,
              onChanged: (open) => setState(() => _open = open),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.gutter,
                vertical: AppSpacing.xs,
              ),
              children: [
                _FilterChip(
                  label: AppStrings.moderationAll,
                  selected: _filter == null,
                  onTap: () => setState(() => _filter = null),
                ),
                for (final target in ReportTarget.values)
                  _FilterChip(
                    label: target.label,
                    selected: _filter == target,
                    onTap: () => setState(() => _filter = target),
                  ),
              ],
            ),
          ),
          Expanded(
            child: AsyncValueWidget(
              value: queue,
              onRetry: () =>
                  ref.invalidate(moderationQueueProvider(open: _open)),
              isEmpty: (list) => list
                  .where((e) => _filter == null || e.target == _filter)
                  .isEmpty,
              empty: EmptyStateView(
                icon: Icons.verified_outlined,
                title: _open
                    ? AppStrings.moderationNothingOpenTitle
                    : AppStrings.moderationNothingClosedTitle,
                message: _open
                    ? AppStrings.moderationNothingOpen
                    : AppStrings.moderationNothingClosed,
              ),
              data: (list) {
                final entries = list
                    .where((e) => _filter == null || e.target == _filter)
                    .toList();
                return ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.gutter,
                    AppSpacing.sm,
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
                          for (var i = 0; i < entries.length; i++) ...[
                            if (i > 0)
                              Divider(
                                height: 1,
                                color: context.tokens.borderSubtle,
                              ),
                            _EntryRow(entry: entries[i]),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Segments extends StatelessWidget {
  const _Segments({
    required this.open,
    required this.openCount,
    required this.onChanged,
  });

  final bool open;
  final int openCount;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    Widget segment(String label, bool selected, VoidCallback onTap) => Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        child: InkWell(
          onTap: onTap,
          child: AnimatedContainer(
            duration: AppMotion.short,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: selected ? t.surface : Colors.transparent,
              borderRadius: AppRadius.brButton,
              border: Border.all(
                color: selected ? t.border : Colors.transparent,
              ),
            ),
            child: Text(
              label,
              style: context.textTheme.titleSmall?.copyWith(
                color: selected ? t.textPrimary : t.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: t.surfaceSunken,
        borderRadius: AppRadius.brButton,
      ),
      child: Row(
        children: [
          segment(
            openCount > 0
                ? '${AppStrings.moderationOpen} · $openCount'
                : AppStrings.moderationOpen,
            open,
            () => onChanged(true),
          ),
          segment(AppStrings.moderationClosed, !open, () => onChanged(false)),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brButton,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? t.brand.withValues(alpha: 0.1) : null,
            borderRadius: AppRadius.brButton,
            border: Border.all(color: selected ? t.brand : t.border),
          ),
          child: Text(
            label,
            style: context.textTheme.labelLarge?.copyWith(
              color: selected ? t.brand : t.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({required this.entry});

  final ModerationEntry entry;

  static IconData iconFor(ReportTarget target) => switch (target) {
    ReportTarget.event => Icons.event_note_outlined,
    ReportTarget.user => Icons.person_outline_rounded,
    ReportTarget.review => Icons.rate_review_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = context.textTheme;
    final when = entry.updatedAt == null
        ? ''
        : ' · ${AppDateFormats.dayMonthTime(entry.updatedAt!)}';
    final subtitle = entry.isOpen
        ? '${AppStrings.reportsCount(entry.reportCount)}$when'
        : '${entry.decision?.label ?? AppStrings.moderationClosed}$when';

    return InkWell(
      onTap: () => context.push(AppRoutes.adminModerationEntryPath(entry.id)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: entry.isOpen ? t.danger.bg : t.surfaceSunken,
                borderRadius: AppRadius.brButton,
              ),
              child: Icon(
                iconFor(entry.target),
                size: 18,
                color: entry.isOpen ? t.danger.fg : t.textSecondary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${entry.target.label} · '
                    '${entry.lastReason?.label ?? AppStrings.unknownReason}',
                    style: text.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(subtitle, style: text.bodySmall, maxLines: 1),
                ],
              ),
            ),
            if (entry.isOpen) ...[
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${entry.reportCount}',
                style: text.titleMedium?.copyWith(
                  color: t.danger.fg,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
            const SizedBox(width: AppSpacing.xs),
            Icon(Icons.chevron_right_rounded, color: t.textTertiary),
          ],
        ),
      ),
    );
  }
}
