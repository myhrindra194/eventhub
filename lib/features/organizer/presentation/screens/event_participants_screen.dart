import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/extensions/context_x.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/utils/date_formats.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/checkin/application/check_in_providers.dart';
import 'package:eventhub/features/events/application/event_providers.dart';
import 'package:eventhub/features/organizer/domain/guest_list_csv.dart';
import 'package:eventhub/features/reservations/application/reservation_providers.dart';
import 'package:eventhub/features/reservations/domain/entities/reservation.dart';
import 'package:eventhub/features/waitlist/application/waitlist_providers.dart';
import 'package:eventhub/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

/// Guest list for one event.
///
/// Le champ de recherche n'est pas un agrément : à la porte, l'organisateur
/// cherche *un* nom dans une liste pendant que quelqu'un attend devant lui.
/// Le filtre porte sur le nom et sur l'e-mail, deux informations qu'un
/// participant récite de mémoire. Chaque ligne indique si la personne a déjà
/// été scannée, et le scanner est à un appui dans la barre.
class EventParticipantsScreen extends ConsumerStatefulWidget {
  const EventParticipantsScreen({required this.eventId, super.key});

  final String eventId;

  @override
  ConsumerState<EventParticipantsScreen> createState() =>
      _EventParticipantsScreenState();
}

class _EventParticipantsScreenState
    extends ConsumerState<EventParticipantsScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// La liste entière, et non la vue filtrée : un export qui laisserait
  /// silencieusement de côté les personnes masquées par une recherche serait
  /// une très mauvaise surprise à la porte.
  Future<void> _copy(List<Reservation> guests) async {
    await Clipboard.setData(ClipboardData(text: GuestListCsv.build(guests)));
    if (!mounted) return;
    final rows = guests.length;
    context.showSuccess(
      '${AppStrings.guestListCopied} · $rows ligne${rows > 1 ? 's' : ''}.',
    );
  }

  /// Un vrai fichier `.csv` passé à la feuille de partage du système (F-15) :
  /// directement vers Drive, un e-mail ou un tableur. Là où le partage de
  /// fichier n'existe pas — certains navigateurs, le bureau — on retombe sur
  /// le presse-papiers plutôt que d'échouer.
  Future<void> _shareFile(List<Reservation> guests, String? title) async {
    final name = GuestListCsv.fileNameFor(title ?? '');
    final box = context.findRenderObject() as RenderBox?;
    try {
      final result = await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              Uint8List.fromList(GuestListCsv.fileBytes(guests)),
              mimeType: 'text/csv',
              name: name,
            ),
          ],
          fileNameOverrides: [name],
          subject: title == null
              ? AppStrings.participants
              : '$title — participants',
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
      if (result.status == ShareResultStatus.unavailable) await _copy(guests);
    } on Object {
      await _copy(guests);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = context.textTheme;
    final event = ref.watch(eventByIdProvider(widget.eventId)).value;
    final participants = ref.watch(eventParticipantsProvider(widget.eventId));
    final guests = participants.value ?? const <Reservation>[];
    final checkIns =
        ref.watch(eventCheckInsProvider(widget.eventId)).value ??
        const <String, DateTime>{};
    final waiting =
        ref.watch(waitlistLengthProvider(widget.eventId)).value ?? 0;

    return AppScaffold(
      dense: true,
      extendBody: false,
      bottomBar: FrostedBar(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          AppSpacing.md,
          AppSpacing.gutter,
          MediaQuery.paddingOf(context).bottom + AppSpacing.md,
        ),
        child: Row(
          children: [
            Expanded(
              child: AppButton.secondary(
                label: AppStrings.exportCsvFile,
                size: AppButtonSize.medium,
                onPressed: guests.isEmpty
                    ? null
                    : () => _shareFile(guests, event?.title),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            IconActionButton(
              icon: Icons.content_copy_rounded,
              tooltip: AppStrings.copyCsv,
              size: 48,
              onPressed: guests.isEmpty ? null : () => _copy(guests),
            ),
          ],
        ),
      ),
      appBar: AppTopBar.subPage(
        title: AppStrings.participants,
        // Le titre de l'événement tient lieu de ligne de contexte : c'est
        // l'information qui répond à « les participants de quoi ? », et elle
        // n'a pas besoin d'une bande supplémentaire sous la barre.
        subtitle: event?.title,
        onBack: () => context.pop(),
        actions: [
          IconButton(
            tooltip: AppStrings.teamTitle,
            icon: const Icon(Icons.diversity_3_rounded),
            onPressed: () =>
                context.push(AppRoutes.organizerEventTeamPath(widget.eventId)),
          ),
          IconButton(
            tooltip: AppStrings.scanTickets,
            icon: const Icon(Icons.qr_code_scanner_rounded),
            onPressed: () => context.push(
              AppRoutes.organizerEventCheckInPath(widget.eventId),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (event != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.md,
                AppSpacing.gutter,
                0,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: StatTile(
                          value: '${event.reservedCount}',
                          label: AppStrings.booked,
                          icon: Icons.how_to_reg_rounded,
                          tone: AppTone.success,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: StatTile(
                          value: '${event.availablePlaces}',
                          label: AppStrings.remaining,
                          icon: Icons.event_seat_rounded,
                          tone: event.isFull ? AppTone.danger : AppTone.brand,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: StatTile(
                          value: '${(event.fillRate * 100).round()}%',
                          label: AppStrings.fillRate,
                          icon: Icons.insights_rounded,
                          tone: AppTone.info,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Icon(
                        Icons.qr_code_scanner_rounded,
                        size: 16,
                        color: t.textTertiary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        AppStrings.checkedInCount(
                          checkIns.length,
                          event.reservedCount,
                        ),
                        style: text.bodySmall,
                      ),
                      if (waiting > 0) ...[
                        const Spacer(),
                        Icon(
                          Icons.hourglass_top_rounded,
                          size: 16,
                          color: t.warning.fg,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          AppStrings.waitlistCount(waiting),
                          style: text.bodySmall?.copyWith(color: t.warning.fg),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.gutter),
            child: AppSearchField(
              hint: AppStrings.searchParticipants,
              controller: _controller,
              value: _query,
              onChanged: (v) => setState(() => _query = v),
              onClear: () {
                _controller.clear();
                setState(() => _query = '');
              },
            ),
          ),
          Expanded(
            child: AsyncValueWidget(
              value: participants,
              onRetry: () =>
                  ref.invalidate(eventParticipantsProvider(widget.eventId)),
              isEmpty: (list) => list.isEmpty,
              empty: const EmptyStateView(
                icon: Icons.person_search_rounded,
                message: AppStrings.noParticipants,
              ),
              data: (list) {
                final query = _query.trim().toLowerCase();
                final filtered = query.isEmpty
                    ? list
                    : list
                          .where(
                            (r) =>
                                r.userName.toLowerCase().contains(query) ||
                                r.userEmail.toLowerCase().contains(query),
                          )
                          .toList();

                if (filtered.isEmpty) {
                  return const EmptyStateView(
                    icon: Icons.person_search_rounded,
                    message: 'Aucun participant ne correspond à ce filtre.',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.gutter,
                    0,
                    AppSpacing.gutter,
                    AppSpacing.huge,
                  ),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) => _ParticipantRow(
                    reservation: filtered[index],
                    index: index,
                    checkedInAt: checkIns[filtered[index].id],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ParticipantRow extends StatelessWidget {
  const _ParticipantRow({
    required this.reservation,
    required this.index,
    required this.checkedInAt,
  });

  final Reservation reservation;
  final int index;

  /// Renseigné une fois le billet scanné à l'entrée.
  final DateTime? checkedInAt;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = context.textTheme;
    final scanned = checkedInAt != null;

    return AppSurface(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderColor: scanned ? t.success.border : null,
      child: Row(
        children: [
          SizedBox(
            width: 26,
            child: Text(
              '${index + 1}',
              style: text.labelSmall?.copyWith(letterSpacing: 0),
              textAlign: TextAlign.center,
            ),
          ),
          AppAvatar(name: reservation.userName, size: 42),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reservation.userName,
                  style: text.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  reservation.tierName == null
                      ? reservation.userEmail
                      : '${reservation.accessLabel} · ${reservation.userEmail}',
                  style: text.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Icon(
                scanned
                    ? Icons.how_to_reg_rounded
                    : Icons.check_circle_outline_rounded,
                size: 16,
                color: scanned ? t.success.fg : t.textTertiary,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                scanned
                    ? '${AppStrings.checkedIn} · '
                          '${AppDateFormats.time(checkedInAt!)}'
                    : AppDateFormats.shortDate(reservation.reservedAt),
                style: text.labelSmall?.copyWith(
                  letterSpacing: 0,
                  color: scanned ? t.success.fg : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
