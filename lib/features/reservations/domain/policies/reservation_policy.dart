import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/events/domain/entities/event.dart';
import 'package:eventhub/features/events/domain/entities/event_tier.dart';
import 'package:eventhub/features/reservations/domain/entities/reservation.dart';

/// Business rules from the spec (§4.4 / §7), extended with ticket types
/// (F-12) and payments (F-11). Pure and unit-tested.
///
/// Why it runs *inside* the booking transaction: Firestore security rules
/// answer a refused write with a bare `permission-denied`, never with the
/// reason. The repository therefore evaluates this policy on the event and
/// the seat the transaction has just read, and turns its precise sentence
/// into a failure before writing anything. `firebase/firestore.rules` checks
/// the same invariants again on the server and is the one that decides — a
/// refusal that still reaches the rules is a race (the last seat just went)
/// or a tampered client.
abstract final class ReservationPolicy {
  /// Online payment needs a server (a Stripe webhook, a refund call) and the
  /// Spark plan has none: the rules refuse any seat with a price. Returned by
  /// every payment entry point until a payment backend exists.
  static const paymentUnavailable = BusinessRuleFailure(
    rule: BusinessRule.paymentRequired,
    message:
        'Le paiement en ligne n’est pas encore disponible : seuls les billets '
        'gratuits sont réservables.',
  );

  /// A free seat, booked directly. [tierId] is required on an event that
  /// has ticket types.
  ///
  /// [userId] is the person booking: one account holds both spaces, so an
  /// organizer books other people's events like anyone else, but the team
  /// of an event (owner and co-organizers) never books its own — the rules
  /// refuse it, because a seat taken by the team would inflate the figures
  /// the team itself reads.
  static Result<void> canReserve({
    required Event event,
    required Reservation? existing,
    required DateTime now,
    String? tierId,
    String? userId,
  }) {
    if (_common(event: event, existing: existing, now: now, userId: userId)
        case Err(:final failure)) {
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
    if (!tier.isFree) return const Err(paymentUnavailable);
    return const Ok(null);
  }

  /// A paid seat. Kept, with its tests, for the day a payment server exists:
  /// no screen calls it on the Spark plan, where [paymentUnavailable] is the
  /// answer.
  static Result<EventTier> canCheckout({
    required Event event,
    required Reservation? existing,
    required DateTime now,
    required String tierId,
    String? userId,
  }) {
    // A still-held checkout for the same event is resumed, not refused.
    final resumable = existing != null && existing.isPending ? null : existing;
    if (_common(event: event, existing: resumable, now: now, userId: userId)
        case Err(:final failure)) {
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
    String? userId,
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
    if (userId != null && event.isManagedBy(userId)) {
      return const Err(
        PermissionFailure(
          message:
              'Vous faites partie de l’équipe de cet événement : vous ne '
              'pouvez pas y réserver de place.',
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

  /// A direct cancellation: free seats only. A paid ticket would need a
  /// refund, which needs a payment server.
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

  /// A refund: a paid, active ticket, before the event starts. Like
  /// [canCheckout], waiting for a payment server.
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
