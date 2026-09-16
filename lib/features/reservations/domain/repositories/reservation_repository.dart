import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/auth/domain/entities/app_user.dart';
import 'package:eventhub/features/reservations/domain/entities/checkout.dart';
import 'package:eventhub/features/reservations/domain/entities/reservation.dart';

abstract interface class ReservationRepository {
  /// Réservations d’un participant, les plus récentes d’abord (tous les
  /// statuts).
  Stream<List<Reservation>> watchByUser(String userId);

  /// Réservations confirmées d’un événement, pour son équipe (propriétaire
  /// et co-organisateurs voient la même liste).
  Stream<List<Reservation>> watchByEvent(String eventId);

  /// Toutes les réservations (tous les statuts) sur les événements de
  /// l’organisateur, les plus récentes d’abord. Alimente ses statistiques
  /// et son fil d’activité.
  Stream<List<Reservation>> watchByOrganizer(String organizerId);

  /// La réservation de la personne pour un événement, `null` sinon.
  Stream<Reservation?> watchForEvent({
    required String eventId,
    required String userId,
  });

  Stream<Reservation?> watchById(String reservationId);

  /// Réserve une place gratuite. `ReservationPolicy` est évaluée à
  /// l’intérieur de la transaction, sur l’événement et la place qu’elle
  /// lit, et la place est décomptée de l’événement (et du type de billet)
  /// de façon atomique.
  AsyncResult<Reservation> reserve({
    required String eventId,
    required AppUser participant,
    String? tierId,
  });

  /// Annule la place gratuite de [userId] et la libère de façon atomique ;
  /// renvoie la réservation annulée.
  AsyncResult<Reservation> cancel({
    required String reservationId,
    required String userId,
  });

  /// Les places payantes (F-11) exigent un serveur de paiement : sur le
  /// plan Spark, ces trois méthodes répondent
  /// `ReservationPolicy.paymentUnavailable`.
  AsyncResult<CheckoutStart> startCheckout({
    required String eventId,
    required String tierId,
  });

  AsyncResult<void> cancelPendingCheckout({required String eventId});

  AsyncResult<void> refund({required String eventId});
}
