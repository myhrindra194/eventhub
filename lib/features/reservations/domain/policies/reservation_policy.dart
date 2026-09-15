import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/events/domain/entities/event.dart';
import 'package:eventhub/features/events/domain/entities/event_tier.dart';
import 'package:eventhub/features/reservations/domain/entities/reservation.dart';

/// Business rules from the spec (§4.4 / §7), extended with ticket types
/// (F-12) and payments (F-11). Pure and unit-tested.
///
/// The app evaluates it for an immediate, precise answer; the database
/// functions (`reserve_seat`, `cancel_reservation`, `payments_hold_seat`)
/// check the same rules again under a row lock and are the ones that decide,
/// so concurrent bookings cannot overbook.
abstract final class ReservationPolicy {
  /// A free seat, booked directly. [tierId] is required on an event that
  /// has ticket types.
  static Result<void> canReserve({
    required Event event,
    required Reservation? existing,
    required DateTime now,
    String? tierId,
  }) {
    if (_common(event: event, existing: existing, now: now) case Err(
      :final failure,
    )) {
      return Err(failure);
    }
    if (!event.hasTiers) return const Ok(null);

    final EventTier tier;
    switch (_tier(event, tierId)) {
      case Ok(:final value):
        tier = value;
      case Err(:final failure):
        return Err(failure);
    }
    if (!tier.isFree) {
      return Err(
        BusinessRuleFailure(
          rule: BusinessRule.paymentRequired,
          message:
              'Le billet « ${tier.name} » est payant : passez au paiement.',
        ),
      );
    }
    return const Ok(null);
  }

  /// A paid seat, through Stripe Checkout. Same checks as the server's
  /// `payments_hold_seat`, so the participant gets a sentence before any
  /// round trip.
  static Result<EventTier> canCheckout({
    required Event event,
    required Reservation? existing,
    required DateTime now,
    required String tierId,
  }) {
    // A still-held checkout for the same event is resumed, not refused.
    final resumable = existing != null && existing.isPending ? null : existing;
    if (_common(event: event, existing: resumable, now: now) case Err(
      :final failure,
    )) {
      return Err(failure);
    }
    final EventTier tier;
    switch (_tier(event, tierId)) {
      case Ok(:final value):
        tier = value;
      case Err(:final failure):
        return Err(failure);
    }
    if (tier.isFree) {
      return Err(
        BusinessRuleFailure(
          rule: BusinessRule.actionRefused,
          message: 'Le billet « ${tier.name} » est gratuit : réservez-le.',
        ),
      );
    }
    return Ok(tier);
  }

  static Result<void> _common({
    required Event event,
    required Reservation? existing,
    required DateTime now,
  }) {
    if (existing != null && existing.isActive) {
      return const Err(
        BusinessRuleFailure(
          rule: BusinessRule.alreadyReserved,
          message: 'Vous avez déjà réservé cet événement.',
        ),
      );
    }
    if (existing != null && existing.isPending) {
      return const Err(
        BusinessRuleFailure(
          rule: BusinessRule.paymentPending,
          message:
              'Un paiement est en cours pour cet événement : terminez-le ou '
              'annulez-le d’abord.',
        ),
      );
    }
    if (event.hasStarted(now)) {
      return const Err(
        BusinessRuleFailure(
          rule: BusinessRule.eventAlreadyStarted,
          message: 'Cet événement a déjà commencé.',
        ),
      );
    }
    if (event.isFull) {
      return const Err(
        BusinessRuleFailure(
          rule: BusinessRule.eventFull,
          message: 'Cet événement est complet.',
        ),
      );
    }
    return const Ok(null);
  }

  static Result<EventTier> _tier(Event event, String? tierId) {
    final tier = tierId == null ? null : event.tier(tierId);
    if (tier == null) {
      return const Err(
        BusinessRuleFailure(
          rule: BusinessRule.tierRequired,
          message: 'Choisissez un type de billet.',
        ),
      );
    }
    if (tier.isSoldOut) {
      return Err(
        BusinessRuleFailure(
          rule: BusinessRule.tierSoldOut,
          message: 'Le billet « ${tier.name} » est complet.',
        ),
      );
    }
    return Ok(tier);
  }

  /// A direct cancellation: free seats only. A paid ticket is refunded by
  /// the `payments-refund` Edge Function instead.
  static Result<void> canCancel({
    required Reservation reservation,
    required String userId,
  }) {
    if (reservation.userId != userId) {
      return const Err(
        BusinessRuleFailure(
          rule: BusinessRule.notReservationOwner,
          message: 'Cette réservation ne vous appartient pas.',
        ),
      );
    }
    if (!reservation.isActive) {
      return const Err(
        BusinessRuleFailure(
          rule: BusinessRule.reservationNotActive,
          message: 'Cette réservation est déjà annulée.',
        ),
      );
    }
    if (reservation.isPaid) {
      return const Err(
        BusinessRuleFailure(
          rule: BusinessRule.refundRequired,
          message: 'Billet payé : l’annulation passe par le remboursement.',
        ),
      );
    }
    return const Ok(null);
  }

  /// A refund: a paid, active ticket, before the event starts.
  static Result<void> canRefund({
    required Reservation reservation,
    required String userId,
    required DateTime now,
  }) {
    if (reservation.userId != userId) {
      return const Err(
        BusinessRuleFailure(
          rule: BusinessRule.notReservationOwner,
          message: 'Cette réservation ne vous appartient pas.',
        ),
      );
    }
    if (!reservation.isActive || !reservation.isPaid) {
      return const Err(
        BusinessRuleFailure(
          rule: BusinessRule.reservationNotActive,
          message: 'Ce billet n’est pas un billet payé en cours.',
        ),
      );
    }
    if (!reservation.eventStartsAt.isAfter(now)) {
      return const Err(
        BusinessRuleFailure(
          rule: BusinessRule.eventAlreadyStarted,
          message:
              'L’événement a commencé : le billet n’est plus remboursable.',
        ),
      );
    }
    return const Ok(null);
  }
}
