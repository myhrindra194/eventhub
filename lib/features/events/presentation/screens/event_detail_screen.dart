import 'dart:async';

import 'package:eventhub/app/theme/theme.dart';
import 'package:eventhub/core/config/app_config.dart';
import 'package:eventhub/core/extensions/context_x.dart';
import 'package:eventhub/core/l10n/app_strings.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/core/utils/date_formats.dart';
import 'package:eventhub/core/widgets/design_system.dart';
import 'package:eventhub/features/auth/application/auth_providers.dart';
import 'package:eventhub/features/events/application/event_providers.dart';
import 'package:eventhub/features/events/domain/entities/event.dart';
import 'package:eventhub/features/events/presentation/widgets/event_card.dart';
import 'package:eventhub/features/reservations/application/reservation_providers.dart';
import 'package:eventhub/features/reservations/domain/entities/reservation.dart';
import 'package:eventhub/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Event detail — the conversion screen.
///
/// Structure follows the decision path: a full-bleed hero establishes the
/// event, a content sheet **overlapping** the image pulls the eye down into
/// the facts, and the action never scrolls away (sticky frosted bar). Four
/// states drive both the copy and the colour of that action: available,
/// last seats, sold out, already booked.
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

/// Availability drives copy, colour and whether the action is enabled.
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
    final mine = ref.watch(myReservationForEventProvider(event.id)).value;
    final reservation = (mine != null && mine.isActive) ? mine : null;
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
                      if (reservation != null) ...[
                        const SizedBox(height: AppSpacing.xxxl),
                        _TicketPreview(reservation: reservation),
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
              OverlayIconButton(
                icon: Icons.ios_share_rounded,
                tooltip: AppStrings.share,
                onPressed: () => context.showToast(AppStrings.comingSoon),
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

    return Row(
      children: [
        AppAvatar(name: event.organizerName),
        const SizedBox(width: AppSpacing.md),
        Expanded(
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
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: t.success.bg,
            borderRadius: AppRadius.brSm,
          ),
          child: Text(
            AppStrings.free,
            style: text.titleMedium?.copyWith(color: t.success.fg),
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
      elevation: SurfaceElevation.flat,
      radius: AppRadius.lg,
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
      elevation: SurfaceElevation.flat,
      radius: AppRadius.lg,
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

/// Gradient ticket teaser shown once the user has booked — a small reward
/// that also tells them where the ticket now lives.
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
        boxShadow: [
          BoxShadow(
            color: t.brand.withValues(alpha: 0.32),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
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

/// Sticky frosted action bar. Never scrolls away: the primary action of a
/// conversion screen must be reachable at any scroll offset.
class _ActionBar extends ConsumerWidget {
  const _ActionBar({
    required this.event,
    required this.availability,
    required this.reservation,
  });

  final Event event;
  final _Availability availability;
  final Reservation? reservation;

  Future<void> _reserve(BuildContext context, WidgetRef ref) async {
    final result = await ref
        .read(reservationControllerProvider.notifier)
        .reserve(event.id);
    if (!context.mounted) return;
    switch (result) {
      case Ok(:final value):
        unawaited(
          context.push(AppRoutes.reservationConfirmationPath(value.id)),
        );
      case Err(:final failure):
        context.showFailure(failure);
    }
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final r = reservation;
    if (r == null) return;
    final confirmed = await showConfirmSheet(
      context,
      icon: Icons.event_busy_rounded,
      title: AppStrings.cancelReservationTitle,
      message: AppStrings.cancelReservationConfirm,
      confirmLabel: AppStrings.cancelReservation,
    );
    if (!confirmed || !context.mounted) return;
    final result = await ref
        .read(reservationControllerProvider.notifier)
        .cancel(r.id);
    if (!context.mounted) return;
    switch (result) {
      case Ok():
        context.showSuccess(AppStrings.reservationCancelled);
      case Err(:final failure):
        context.showFailure(failure);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBusy = ref.watch(reservationControllerProvider).isLoading;
    final isParticipant =
        ref.watch(currentUserProvider)?.isParticipant ?? false;
    final bottom = MediaQuery.paddingOf(context).bottom;

    final Widget action;
    if (reservation != null) {
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
              icon: Icons.confirmation_number_rounded,
              onPressed: () => context.go(AppRoutes.reservations),
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
        _Availability.soldOut => const AppButton.primary(
          label: AppStrings.soldOut,
          onPressed: null,
        ),
        _Availability.lastSeats => AppButton(
          label: AppStrings.grabLast,
          variant: AppButtonVariant.danger,
          icon: Icons.local_fire_department_rounded,
          isLoading: isBusy,
          loadingLabel: 'Réservation…',
          onPressed: isParticipant ? () => _reserve(context, ref) : null,
        ),
        _Availability.available => AppButton.primary(
          label: AppStrings.reserve,
          icon: Icons.confirmation_number_rounded,
          isLoading: isBusy,
          loadingLabel: 'Réservation…',
          onPressed: isParticipant ? () => _reserve(context, ref) : null,
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
