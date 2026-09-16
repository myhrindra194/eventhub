import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/config/app_config.dart';
import 'package:eventhub/core/extensions/context_x.dart';
import 'package:eventhub/core/utils/date_formats.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/events/domain/entities/event.dart';
import 'package:eventhub/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// « Scanner un billet », directement depuis la barre de l'espace
/// organisateur.
///
/// Le scanner existait, mais au bout d'un chemin : Mes événements → un
/// événement → Participants → Scanner. À l'entrée d'une salle, avec une file
/// qui attend, quatre écrans sont trois de trop. Cette action ouvre un menu
/// déroulant des événements que l'on peut contrôler maintenant — ceux qui
/// ont lieu aujourd'hui en premier, puis les prochains — et un seul toucher
/// mène au scanner de l'événement choisi.
///
/// Un menu plutôt qu'un écran intermédiaire : la liste est courte, et le
/// choix se fait sans quitter l'écran.
class ScanTicketsAction extends ConsumerWidget {
  const ScanTicketsAction({required this.events, super.key});

  /// Événements dont l'utilisateur est propriétaire ou co-organisateur.
  final List<Event> events;

  /// Un billet se contrôle le jour J ; on propose aussi les événements de la
  /// semaine, pour qu'un organisateur puisse vérifier son matériel la veille.
  static const _horizon = Duration(days: 7);

  /// Un événement commencé depuis moins de 12 heures accueille encore du
  /// monde : il reste dans la liste.
  static const _grace = Duration(hours: 12);

  static List<Event> scannable(List<Event> events, DateTime now) {
    final list =
        events
            .where(
              (e) =>
                  e.startsAt.isAfter(now.subtract(_grace)) &&
                  e.startsAt.isBefore(now.add(_horizon)),
            )
            .toList()
          ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    return list;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final text = context.textTheme;
    final now = ref.watch(clockProvider)();
    final candidates = scannable(events, now);

    return MenuAnchor(
      alignmentOffset: const Offset(0, AppSpacing.xs),
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(t.surfaceOverlay),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        shadowColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(0),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: AppRadius.brButton,
            side: BorderSide(color: t.border),
          ),
        ),
      ),
      menuChildren: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.xs,
          ),
          child: Text(
            'SCANNER LES BILLETS DE',
            style: text.labelSmall?.copyWith(
              color: t.textTertiary,
              letterSpacing: 0.8,
            ),
          ),
        ),
        if (candidates.isEmpty)
          MenuItemButton(
            child: Text(
              'Aucun événement cette semaine',
              style: text.bodyMedium?.copyWith(color: t.textTertiary),
            ),
          )
        else
          for (final event in candidates)
            MenuItemButton(
              onPressed: () =>
                  context.push(AppRoutes.organizerEventCheckInPath(event.id)),
              style: MenuItemButton.styleFrom(
                minimumSize: const Size(260, 52),
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.brButton,
                ),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      event.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleSmall,
                    ),
                    Text(
                      DateUtils.isSameDay(event.startsAt, now)
                          ? 'Aujourd’hui · '
                                '${AppDateFormats.time(event.startsAt)}'
                          : AppDateFormats.dayMonthTime(event.startsAt),
                      style: text.bodySmall?.copyWith(
                        color: DateUtils.isSameDay(event.startsAt, now)
                            ? t.brand
                            : t.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ],
      builder: (context, controller, _) => IconActionButton(
        icon: Icons.qr_code_scanner_rounded,
        tooltip: 'Scanner un billet',
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}
