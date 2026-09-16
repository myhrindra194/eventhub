import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/config/app_config.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/reservations/application/reservation_providers.dart';
import 'package:eventhub/features/reservations/domain/entities/reservation.dart';
import 'package:eventhub/features/reservations/presentation/widgets/reservation_tile.dart';
import 'package:eventhub/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// La tranche du portefeuille actuellement affichée.
enum _TicketTab {
  upcoming,
  past,
  cancelled;

  String get label => switch (this) {
    _TicketTab.upcoming => AppStrings.upcomingEvents,
    _TicketTab.past => AppStrings.pastEvents,
    _TicketTab.cancelled => AppStrings.statusCancelled,
  };
}

/// « Mes billets » — le portefeuille.
///
/// Segmenté plutôt qu’une longue liste à sections : celui qui ouvre cet
/// écran veut presque toujours le *prochain* billet, et mêler les billets
/// annulés et passés au même défilement l’y enterre. Le compteur porté par
/// chaque segment garde les autres tranches repérables sans les afficher.
class MyReservationsScreen extends ConsumerStatefulWidget {
  const MyReservationsScreen({super.key});

  @override
  ConsumerState<MyReservationsScreen> createState() =>
      _MyReservationsScreenState();
}

class _MyReservationsScreenState extends ConsumerState<MyReservationsScreen> {
  _TicketTab _tab = _TicketTab.upcoming;

  @override
  Widget build(BuildContext context) {
    final reservations = ref.watch(myReservationsProvider);
    final now = ref.watch(clockProvider)();

    return AppScaffold(
      constrainWidth: false,
      dense: true,
      appBar: const AppTopBar.root(
        title: AppStrings.myReservations,
        subtitle: 'Vos places réservées, prêtes à présenter à l’entrée.',
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(myReservationsProvider),
          child: CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),
              AsyncValueWidget(
                value: reservations,
                sliver: true,
                onRetry: () => ref.invalidate(myReservationsProvider),
                isEmpty: (list) => list.isEmpty,
                loading: SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.gutter,
                  ),
                  sliver: SliverList.separated(
                    itemCount: 3,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (_, __) => const Skeleton(height: 132),
                  ),
                ),
                empty: SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyStateView(
                    icon: Icons.confirmation_number_outlined,
                    title: AppStrings.noTicketsTitle,
                    message: AppStrings.noTickets,
                    action: AppButton.primary(
                      label: AppStrings.exploreEvents,
                      expand: false,
                      onPressed: () => context.go(AppRoutes.events),
                    ),
                  ),
                ),
                data: (list) => _Content(
                  reservations: list,
                  now: now,
                  tab: _tab,
                  onTabChanged: (tab) => setState(() => _tab = tab),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: AppSizes.navBarInset),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.reservations,
    required this.now,
    required this.tab,
    required this.onTabChanged,
  });

  final List<Reservation> reservations;
  final DateTime now;
  final _TicketTab tab;
  final ValueChanged<_TicketTab> onTabChanged;

  List<Reservation> _slice(_TicketTab tab) => switch (tab) {
    // Un achat en cours a sa place parmi les billets à venir : c’est là que
    // l’utilisateur le cherche, et là qu’il finit de payer.
    _TicketTab.upcoming =>
      reservations
          .where(
            (r) => (r.isActive || r.isPending) && r.eventStartsAt.isAfter(now),
          )
          .toList(),
    _TicketTab.past =>
      reservations
          .where((r) => r.isActive && !r.eventStartsAt.isAfter(now))
          .toList(),
    _TicketTab.cancelled => reservations.where((r) => r.isCancelled).toList(),
  };

  @override
  Widget build(BuildContext context) {
    final items = _slice(tab);

    return SliverList.list(
      children: [
        _Segments(
          selected: tab,
          counts: {for (final t in _TicketTab.values) t: _slice(t).length},
          onChanged: onTabChanged,
        ),
        const SizedBox(height: AppSpacing.xl),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.giant),
            child: EmptyStateView(
              icon: switch (tab) {
                _TicketTab.upcoming => Icons.event_available_rounded,
                _TicketTab.past => Icons.history_rounded,
                _TicketTab.cancelled => Icons.event_busy_rounded,
              },
              message: switch (tab) {
                _TicketTab.upcoming => 'Aucun billet à venir pour le moment.',
                _TicketTab.past => 'Vos événements passés apparaîtront ici.',
                _TicketTab.cancelled => 'Aucune réservation annulée.',
              },
            ),
          )
        else
          for (final r in items) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.gutter,
              ),
              child: TicketCard(
                reservation: r,
                isPast: tab != _TicketTab.upcoming,
                onTap: () => context.push(
                  r.isPending
                      ? AppRoutes.paymentPath(r.id)
                      : AppRoutes.ticketPath(r.id),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
      ],
    );
  }
}

/// Contrôle segmenté en pilule, avec un compteur par segment.
class _Segments extends StatelessWidget {
  const _Segments({
    required this.selected,
    required this.counts,
    required this.onChanged,
  });

  final _TicketTab selected;
  final Map<_TicketTab, int> counts;
  final ValueChanged<_TicketTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xs),
        decoration: BoxDecoration(
          color: t.surfaceSunken,
          borderRadius: AppRadius.brMd,
          border: Border.all(color: t.borderSubtle),
        ),
        child: Row(
          children: [
            for (final tab in _TicketTab.values)
              Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(tab),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: AppMotion.short,
                    curve: AppMotion.standard,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      // Le segment actif se distingue par sa surface claire
                      // sur le creux du rail — aucune ombre n’est
                      // nécessaire.
                      color: tab == selected ? t.surface : Colors.transparent,
                      borderRadius: AppRadius.brSm,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            tab.label,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: tab == selected
                                      ? t.textPrimary
                                      : t.textSecondary,
                                ),
                          ),
                        ),
                        if ((counts[tab] ?? 0) > 0) ...[
                          const SizedBox(width: AppSpacing.sm),
                          CountBadge(
                            count: counts[tab]!,
                            tone: tab == selected
                                ? AppTone.brand
                                : AppTone.neutral,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
