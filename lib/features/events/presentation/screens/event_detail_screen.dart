import 'dart:async';

import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/config/app_config.dart';
import 'package:eventhub/core/extensions/context_x.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/core/utils/date_formats.dart';
import 'package:eventhub/core/utils/money.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/auth/application/auth_providers.dart';
import 'package:eventhub/features/events/application/event_providers.dart';
import 'package:eventhub/features/events/domain/entities/event.dart';
import 'package:eventhub/features/events/presentation/widgets/event_card.dart';
import 'package:eventhub/features/events/presentation/widgets/share_event_sheet.dart';
import 'package:eventhub/features/events/presentation/widgets/social_proof_row.dart';
import 'package:eventhub/features/events/presentation/widgets/ticket_types.dart';
import 'package:eventhub/features/favorites/presentation/widgets/favorite_button.dart';
import 'package:eventhub/features/moderation/domain/report.dart';
import 'package:eventhub/features/moderation/presentation/widgets/report_sheet.dart';
import 'package:eventhub/features/reservations/application/reservation_providers.dart';
import 'package:eventhub/features/reservations/domain/entities/reservation.dart';
import 'package:eventhub/features/reservations/domain/policies/reservation_policy.dart';
import 'package:eventhub/features/reviews/presentation/widgets/reviews_section.dart';
import 'package:eventhub/features/waitlist/presentation/widgets/waitlist_action.dart';
import 'package:eventhub/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Détail d’un événement — l’écran de conversion.
///
/// La structure suit le chemin de décision : un visuel pleine largeur pose
/// l’événement, une feuille de contenu qui **chevauche** l’image attire
/// l’œil vers les faits, et l’action ne défile jamais hors de portée (barre
/// dépolie collée en bas). Quatre états pilotent à la fois le texte et la
/// couleur de cette action : disponible, dernières places, complet, déjà
/// réservé.
class EventDetailScreen extends ConsumerWidget {
  const EventDetailScreen({required this.eventId, super.key});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final event = ref.watch(eventByIdProvider(eventId));

    return AppScaffold(
      constrainWidth: false,
      showBlooms: false,
      body: AsyncValueWidget(
        value: event,
        onRetry: () => ref.invalidate(eventByIdProvider(eventId)),
        isEmpty: (e) => e == null,
        loading: const _DetailSkeleton(),
        empty: const _NotFound(),
        data: (e) => _Body(event: e!),
      ),
    );
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound();

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Align(
          alignment: Alignment.centerLeft,
          child: SafeArea(
            child: IconActionButton(
              icon: Icons.arrow_back_rounded,
              onPressed: () => context.pop(),
            ),
          ),
        ),
      ),
      const Expanded(
        child: EmptyStateView(
          icon: Icons.link_off_rounded,
          message: AppStrings.eventNotFound,
        ),
      ),
    ],
  );
}

/// La disponibilité pilote le texte, la couleur et l’activation de
/// l’action.
enum _Availability {
  available,
  lastSeats,
  soldOut,
  past;

  static const lastSeatsThreshold = 3;

  static _Availability of(Event event, DateTime now) {
    if (event.hasStarted(now)) return _Availability.past;
    if (event.isFull) return _Availability.soldOut;
    if (event.availablePlaces <= lastSeatsThreshold) {
      return _Availability.lastSeats;
    }
    return _Availability.available;
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final text = context.textTheme;
    final now = ref.watch(clockProvider)();
    final user = ref.watch(currentUserProvider);
    final mine = ref.watch(myReservationForEventProvider(event.id)).value;
    final reservation = (mine != null && mine.isActive) ? mine : null;
    final pending = (mine != null && mine.isPending) ? mine : null;
    final availability = _Availability.of(event, now);

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _Hero(event: event)),
            SliverToBoxAdapter(
              child: Transform.translate(
                offset: const Offset(0, -32),
                child: Container(
                  decoration: BoxDecoration(
                    color: t.canvas,
                    borderRadius: AppRadius.brSheet,
                  ),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.gutter,
                    AppSpacing.xxl,
                    AppSpacing.gutter,
                    160,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _StatusRow(
                        availability: availability,
                        reserved: reservation != null,
                        seats: event.availablePlaces,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        event.title,
                        style: text.displaySmall?.copyWith(height: 1.15),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _OrganizerRow(event: event),
                      SocialProofRow(event: event),
                      const SizedBox(height: AppSpacing.xxl),
                      const SectionLabel(AppStrings.practicalInfo),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: _InfoTile(
                              icon: Icons.calendar_month_rounded,
                              label: AppStrings.date,
                              value: AppDateFormats.shortDate(event.startsAt),
                              sub: AppDateFormats.weekdayDate(event.startsAt),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _InfoTile(
                              icon: Icons.schedule_rounded,
                              label: AppStrings.time,
                              value: AppDateFormats.time(event.startsAt),
                              sub: "Heure d'ouverture",
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _InfoTile(
                        icon: Icons.place_rounded,
                        label: AppStrings.location,
                        value: event.location,
                        sub: event.category.label,
                        wide: true,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _CapacityCard(event: event),
                      if (event.hasTiers) ...[
                        const SizedBox(height: AppSpacing.xxl),
                        TicketTypesSection(event: event),
                      ],
                      const SizedBox(height: AppSpacing.xxxl),
                      const SectionLabel(AppStrings.aboutEvent),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        event.description,
                        style: text.bodyLarge?.copyWith(
                          color: t.textSecondary,
                          height: 1.65,
                        ),
                      ),
                      ReviewsSection(event: event),
                      if (reservation != null) ...[
                        const SizedBox(height: AppSpacing.xxxl),
                        GestureDetector(
                          onTap: () => context.push(
                            AppRoutes.ticketPath(reservation.id),
                          ),
                          child: _TicketPreview(reservation: reservation),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        Positioned(
          top: MediaQuery.paddingOf(context).top + AppSpacing.sm,
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          child: Row(
            children: [
              OverlayIconButton(
                icon: Icons.arrow_back_rounded,
                tooltip: AppStrings.goBack,
                onPressed: () => context.canPop()
                    ? context.pop()
                    : context.go(AppRoutes.events),
              ),
              const Spacer(),
              if (user != null && !event.isManagedBy(user.id)) ...[
                OverlayIconButton(
                  icon: Icons.flag_outlined,
                  tooltip: AppStrings.reportAction,
                  onPressed: () => showReportSheet(
                    context,
                    target: ReportTarget.event,
                    targetId: event.id,
                    subject: event.title,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              FavoriteButton(eventId: event.id),
              const SizedBox(width: AppSpacing.sm),
              OverlayIconButton(
                icon: Icons.ios_share_rounded,
                tooltip: AppStrings.share,
                onPressed: () => showShareEventSheet(context, event),
              ),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _ActionBar(
            event: event,
            availability: availability,
            reservation: reservation,
            pending: pending,
          ),
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return SizedBox(
      height: 392,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Hero(
            tag: 'event-image-${event.id}',
            child: EventImage(imageUrl: event.imageUrl, seed: event.id),
          ),
          DecoratedBox(decoration: BoxDecoration(gradient: t.heroScrim)),
          Positioned(
            left: AppSpacing.gutter,
            bottom: AppSpacing.huge,
            child: CategoryChip(category: event.category),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.availability,
    required this.reserved,
    required this.seats,
  });

  final _Availability availability;
  final bool reserved;
  final int seats;

  @override
  Widget build(BuildContext context) {
    if (reserved) {
      return const AppBadge(
        label: AppStrings.reserved,
        tone: AppTone.success,
        style: BadgeStyle.solid,
        icon: Icons.check_circle_rounded,
      );
    }

    final (badge, caption, tone) = switch (availability) {
      _Availability.available => (
        const AppBadge(
          label: AppStrings.available,
          tone: AppTone.success,
          style: BadgeStyle.outline,
        ),
        '$seats ${AppStrings.seatsLeft}',
        AppTone.success,
      ),
      _Availability.lastSeats => (
        const AppBadge(
          label: AppStrings.sellingFast,
          tone: AppTone.warning,
          icon: Icons.local_fire_department_rounded,
        ),
        '${AppStrings.onlyLeft} $seats place${seats > 1 ? 's' : ''} !',
        AppTone.warning,
      ),
      _Availability.soldOut => (
        const AppBadge(label: AppStrings.noVacancy, tone: AppTone.danger),
        '',
        AppTone.danger,
      ),
      _Availability.past => (
        const AppBadge(label: AppStrings.past, tone: AppTone.neutral),
        '',
        AppTone.neutral,
      ),
    };

    return Row(
      children: [
        badge,
        if (caption.isNotEmpty) ...[
          const SizedBox(width: AppSpacing.md),
          Text(
            caption,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.tokens.resolve(tone).fg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _OrganizerRow extends StatelessWidget {
  const _OrganizerRow({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    // Tout le bloc d’identité ouvre le profil public de l’organisateur
    // (F-10) ; le chevron le dit, sans lien « voir le profil » séparé.
    return Row(
      children: [
        Expanded(
          child: Semantics(
            button: true,
            label: '${AppStrings.seeOrganizerProfile} ${event.organizerName}',
            excludeSemantics: true,
            child: InkWell(
              borderRadius: AppRadius.brButton,
              onTap: () => context.push(
                AppRoutes.organizerPublicProfilePath(event.organizerId),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  children: [
                    AppAvatar(name: event.organizerName),
                    const SizedBox(width: AppSpacing.md),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppStrings.organizer, style: text.labelSmall),
                          Text(
                            event.organizerName,
                            style: text.titleMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: t.textTertiary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: event.isFree ? t.success.bg : t.brand.withValues(alpha: 0.1),
            borderRadius: AppRadius.brButton,
          ),
          child: Text(
            eventPriceLabel(event),
            style: text.titleMedium?.copyWith(
              color: event.isFree ? t.success.fg : t.brand,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
    this.wide = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final String sub;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(label),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: text.titleMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          sub,
          style: text.bodySmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );

    return AppSurface(
      child: wide
          ? Row(
              children: [
                IconTile(icon: icon, size: 40),
                const SizedBox(width: AppSpacing.lg),
                Expanded(child: content),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconTile(icon: icon, size: 36),
                const SizedBox(height: AppSpacing.md),
                content,
              ],
            ),
    );
  }
}

class _CapacityCard extends StatelessWidget {
  const _CapacityCard({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel(AppStrings.capacity),
          const SizedBox(height: AppSpacing.md),
          CapacityMeter(
            available: event.availablePlaces,
            capacity: event.capacity,
            height: 8,
          ),
        ],
      ),
    );
  }
}

/// Aperçu du billet en dégradé, affiché une fois la réservation faite — une
/// petite récompense, qui dit aussi où le billet se trouve désormais.
class _TicketPreview extends StatelessWidget {
  const _TicketPreview({required this.reservation});

  final Reservation reservation;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: t.brandGradient,
        borderRadius: AppRadius.brXl,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.yourTicket.toUpperCase(),
                  style: text.labelSmall?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  AppStrings.standardSeat,
                  style: text.titleLarge?.copyWith(color: Colors.white),
                ),
                Text(
                  AppStrings.generalAccess,
                  style: text.bodySmall?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  '${AppStrings.reservedOn} '
                  '${AppDateFormats.dayMonthTime(reservation.reservedAt)}',
                  style: text.labelSmall?.copyWith(
                    color: Colors.white70,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadius.brSm,
            ),
            child: const Icon(
              Icons.qr_code_2_rounded,
              color: AppPalette.neutral900,
              size: 38,
            ),
          ),
        ],
      ),
    );
  }
}

/// Barre d’action dépolie, collée en bas. Elle ne défile jamais : l’action
/// principale d’un écran de conversion doit rester atteignable quel que
/// soit le défilement.
class _ActionBar extends ConsumerWidget {
  const _ActionBar({
    required this.event,
    required this.availability,
    required this.reservation,
    required this.pending,
  });

  final Event event;
  final _Availability availability;
  final Reservation? reservation;

  /// Une place payante retenue pendant que l’utilisateur était sur la page
  /// Stripe (F-11).
  final Reservation? pending;

  /// Un événement simple se réserve directement ; un événement à types de
  /// billets demande d’abord lequel. Sans serveur de paiement, seule une
  /// place gratuite est réservable : le sélecteur laisse les types payants
  /// désactivés.
  Future<void> _reserve(BuildContext context, WidgetRef ref) async {
    String? tierId;
    if (event.hasTiers) {
      final tier = await showTicketTypePicker(context, event);
      if (tier == null || !context.mounted) return;
      if (!tier.isFree) {
        context.showFailure(ReservationPolicy.paymentUnavailable);
        return;
      }
      tierId = tier.id;
    }
    final result = await ref
        .read(reservationControllerProvider.notifier)
        .reserve(event.id, tierId: tierId);
    if (!context.mounted) return;
    switch (result) {
      // La place est prise : on montre tout de suite le billet, QR compris —
      // c'est ce que la personne vient chercher, et ce qu'elle présentera à
      // l'entrée (le parcours d'Eventbrite et de Dice).
      case Ok(:final value):
        context.showSuccess(AppStrings.bookedShowTicket);
        unawaited(context.push(AppRoutes.ticketPath(value.id)));
      case Err(:final failure):
        context.showFailure(failure);
    }
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final r = reservation;
    if (r == null) return;
    final price = Money.format(r.pricePaid, r.currency ?? event.currencyCode);
    final confirmed = await showConfirmSheet(
      context,
      icon: r.isPaid
          ? Icons.currency_exchange_rounded
          : Icons.event_busy_rounded,
      title: r.isPaid
          ? AppStrings.refundTitle
          : AppStrings.cancelReservationTitle,
      message: r.isPaid
          ? AppStrings.refundMessage(price)
          : AppStrings.cancelReservationConfirm,
      confirmLabel: r.isPaid
          ? AppStrings.refundTicket
          : AppStrings.cancelReservation,
    );
    if (!confirmed || !context.mounted) return;
    final controller = ref.read(reservationControllerProvider.notifier);
    final result = r.isPaid
        ? await controller.refund(event.id)
        : await controller.cancel(r.id);
    if (!context.mounted) return;
    switch (result) {
      case Ok():
        context.showSuccess(
          r.isPaid ? AppStrings.refunded : AppStrings.reservationCancelled,
        );
      case Err(:final failure):
        context.showFailure(failure);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBusy = ref.watch(reservationControllerProvider).isLoading;
    // Un compte, deux espaces : tout compte connecté réserve ou s’inscrit
    // en liste d’attente, sauf l’équipe de l’événement, que les règles
    // refusent.
    final user = ref.watch(currentUserProvider);
    final canBook = user != null && !event.isManagedBy(user.id);
    final bottom = MediaQuery.paddingOf(context).bottom;

    // Un événement entièrement payant dit « choisir un billet » plutôt que
    // « réserver ma place ».
    final bookLabel = event.hasTiers && !event.hasFreeTier
        ? AppStrings.chooseTicket
        : AppStrings.reserve;

    final Widget action;
    if (pending != null) {
      action = AppButton.primary(
        label: AppStrings.paymentInProgress,
        onPressed: () => context.push(AppRoutes.paymentPath(pending!.id)),
      );
    } else if (reservation != null) {
      action = Row(
        children: [
          Expanded(
            child: AppButton.secondary(
              label: AppStrings.cancel,
              onPressed: isBusy ? null : () => _cancel(context, ref),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 2,
            child: AppButton.primary(
              label: AppStrings.viewTicket,
              onPressed: () =>
                  context.push(AppRoutes.ticketPath(reservation!.id)),
            ),
          ),
        ],
      );
    } else {
      action = switch (availability) {
        _Availability.past => const AppButton.primary(
          label: AppStrings.past,
          onPressed: null,
        ),
        // Un événement complet est une file d’attente, pas un cul-de-sac.
        _Availability.soldOut =>
          canBook
              ? WaitlistAction(event: event)
              : const AppButton.primary(
                  label: AppStrings.soldOut,
                  onPressed: null,
                ),
        _Availability.lastSeats => AppButton(
          label: AppStrings.grabLast,
          variant: AppButtonVariant.danger,
          isLoading: isBusy,
          loadingLabel: 'Réservation…',
          onPressed: canBook ? () => _reserve(context, ref) : null,
        ),
        _Availability.available => AppButton.primary(
          label: bookLabel,
          isLoading: isBusy,
          loadingLabel: 'Réservation…',
          onPressed: canBook ? () => _reserve(context, ref) : null,
        ),
      };
    }

    return FrostedBar(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.lg,
        AppSpacing.gutter,
        bottom + AppSpacing.lg,
      ),
      child: action,
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Skeleton(height: 392, radius: 0),
      SizedBox(height: AppSpacing.xl),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Skeleton(width: 110, height: 24),
            SizedBox(height: AppSpacing.lg),
            Skeleton(height: 30),
            SizedBox(height: AppSpacing.sm),
            Skeleton(width: 220, height: 30),
            SizedBox(height: AppSpacing.xxl),
            SkeletonParagraph(lines: 4),
          ],
        ),
      ),
    ],
  );
}
