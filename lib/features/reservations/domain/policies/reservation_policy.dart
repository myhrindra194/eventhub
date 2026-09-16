import 'package:eventhub/core/errors/failure.dart';
import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/events/domain/entities/event.dart';
import 'package:eventhub/features/events/domain/entities/event_tier.dart';
import 'package:eventhub/features/reservations/domain/entities/reservation.dart';

/// Règles métier du cahier des charges (§4.4 / §7), étendues aux types de
/// billets (F-12) et aux paiements (F-11). Pures et couvertes par des tests
/// unitaires.
///
/// Pourquoi elles s’exécutent *à l’intérieur* de la transaction de
/// réservation : les règles de sécurité Firestore répondent à une écriture
/// refusée par un simple `permission-denied`, jamais par le motif. Le
/// repository évalue donc cette policy sur l’événement et la place que la
/// transaction vient de lire, et transforme sa phrase précise en failure
/// avant la moindre écriture. `firebase/firestore.rules` revérifie les
/// mêmes invariants côté serveur et reste seul juge : un refus qui atteint
/// malgré tout les règles signale une course (la dernière place vient de
/// partir) ou un client trafiqué.
abstract final class ReservationPolicy {
  /// Le paiement en ligne exige un serveur (un webhook Stripe, un appel de
  /// remboursement) et le plan Spark n’en a pas : les règles refusent toute
  /// place ayant un prix. Renvoyé par chaque point d’entrée de paiement
  /// tant qu’il n’existe pas de backend de paiement.
  static const paymentUnavailable = BusinessRuleFailure(
    rule: BusinessRule.paymentRequired,
    message:
        'Le paiement en ligne n’est pas encore disponible : seuls les billets '
        'gratuits sont réservables.',
  );

  /// Une place gratuite, réservée directement. [tierId] est obligatoire sur
  /// un événement qui possède des types de billets.
  ///
  /// [userId] est la personne qui réserve : un seul compte porte les deux
  /// espaces, si bien qu’un organisateur réserve les événements des autres
  /// comme n’importe qui, mais l’équipe d’un événement (propriétaire et
  /// co-organisateurs) ne réserve jamais le sien — les règles le refusent,
  /// car une place prise par l’équipe gonflerait les chiffres que cette
  /// même équipe consulte.
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

  /// Une place payante. Conservée, avec ses tests, pour le jour où un
  /// serveur de paiement existera : aucun écran ne l’appelle sur le plan
  /// Spark, où la réponse est [paymentUnavailable].
  static Result<EventTier> canCheckout({
    required Event event,
    required Reservation? existing,
    required DateTime now,
    required String tierId,
    String? userId,
  }) {
    // Un paiement encore en cours sur le même événement est repris, non
    // refusé.
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

  /// Une annulation directe : places gratuites uniquement. Un billet payé
  /// exigerait un remboursement, donc un serveur de paiement.
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

  /// Un remboursement : un billet payé et actif, avant le début de
  /// l’événement. Comme [canCheckout], en attente d’un serveur de paiement.
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
