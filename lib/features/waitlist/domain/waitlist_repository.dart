import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/auth/domain/entities/app_user.dart';
import 'package:eventhub/features/events/domain/entities/event.dart';
import 'package:eventhub/features/reservations/domain/entities/reservation.dart';

abstract interface class WaitlistRepository {
  /// Les règles n’autorisent un client à lister au plus que ce nombre
  /// d’entrées d’une file.
  static const queueLengthCap = 20;

  /// Indique si [userId] est en file d’attente pour [eventId].
  Stream<bool> watchIsWaiting({
    required String eventId,
    required String userId,
  });

  /// Nombre de personnes en file, pour l’équipe de l’événement, plafonné à
  /// [queueLengthCap] : une valeur égale au plafond se lit « 20 ou plus ».
  Stream<int> watchQueueLength(String eventId);

  /// Vérifie `WaitlistPolicy.canJoin` avant d’écrire ; les règles
  /// revérifient ensuite les mêmes conditions.
  AsyncResult<void> join({
    required Event event,
    required AppUser user,
    required Reservation? reservation,
    required DateTime now,
  });

  /// Retire l’entrée propre à [userId] ; sans effet s’il n’y en a pas.
  AsyncResult<void> leave({required String eventId, required String userId});
}
