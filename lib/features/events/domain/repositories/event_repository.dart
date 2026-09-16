import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/auth/domain/entities/app_user.dart';
import 'package:eventhub/features/events/domain/entities/event.dart';
import 'package:eventhub/features/events/domain/entities/event_draft.dart';

abstract interface class EventRepository {
  /// Événements commençant à [from] ou après, triés par date de début.
  Stream<List<Event>> watchUpcoming({required DateTime from});

  /// Tous les événements d’un organisateur, du plus récent au plus ancien.
  Stream<List<Event>> watchByOrganizer(String organizerId);

  /// Événements co-organisés par [userId], du plus récent au plus ancien.
  Stream<List<Event>> watchCoOrganized(String userId);

  /// Émet `null` quand l’événement n’existe pas (ou a été supprimé).
  Stream<Event?> watchById(String eventId);

  AsyncResult<Event> getById(String eventId);

  /// Renvoie l’identifiant du nouvel événement.
  AsyncResult<String> create({
    required EventDraft draft,
    required AppUser organizer,
  });

  /// Vérifie la propriété et garde `availablePlaces` cohérent avec les
  /// réservations déjà faites lorsque la capacité change.
  AsyncResult<void> update({
    required String eventId,
    required EventDraft draft,
    required AppUser organizer,
  });

  /// Les [limit] événements à venir qui suivent [after], dans le même
  /// ordre que [watchUpcoming] (`startsAt`, puis id). Requête ponctuelle :
  /// les pages plus anciennes du catalogue sont chargées à la demande et
  /// rafraîchies par le tirer-pour-rafraîchir.
  AsyncResult<List<Event>> fetchUpcomingAfter({
    required DateTime from,
    required Event after,
    required int limit,
  });

  AsyncResult<void> delete({
    required String eventId,
    required AppUser organizer,
  });
}
