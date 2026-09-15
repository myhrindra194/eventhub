import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/extensions/context_x.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/events/application/attendance_providers.dart';
import 'package:eventhub/features/events/domain/entities/event.dart';
import 'package:eventhub/features/events/domain/entities/event_attendance.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// « Soa, Hery R. et 40 autres y vont » with the faces of the latest people
/// who booked (F-07).
///
/// Absent when nobody booked. The count is the event's own seat counter, so
/// it is exact even before the aggregate document catches up; the names
/// arrive a moment later and the sentence simply gains them.
class SocialProofRow extends ConsumerWidget {
  const SocialProofRow({required this.event, super.key});

  final Event event;

  static const _faces = 4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final names =
        ref.watch(eventRecentAttendeesProvider(event.id)).value ??
        const <String>[];
    final sentence = Attendance.sentence(
      going: event.reservedCount,
      names: names,
    );
    if (sentence == null) return const SizedBox.shrink();

    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Semantics(
        label: sentence,
        excludeSemantics: true,
        child: Row(
          children: [
            if (names.isEmpty)
              Icon(Icons.groups_2_outlined, size: 22, color: t.textSecondary)
            else
              AvatarStack(names: names.take(_faces).toList()),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                sentence,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: t.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
