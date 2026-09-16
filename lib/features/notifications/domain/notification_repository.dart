import 'package:eventhub/core/result/result.dart';
import 'package:eventhub/features/notifications/domain/app_notification.dart';
import 'package:eventhub/features/notifications/domain/notification_preferences.dart';

/// L’historique de notifications in-app, les préférences qui le filtrent, et
/// les jetons d’appareil dont un émetteur aurait besoin.
///
/// Il n’y a pas de serveur sur le plan Spark : une notification est écrite par
/// celui qui l’a provoquée (une réservation, une annulation, une décision de
/// modération), sous des règles qui prouvent le fait avant d’accepter la
/// notification. Envoyer un push vers une application fermée demanderait des
/// Cloud Functions — les jetons sont enregistrés malgré tout, si bien que
/// l’activer plus tard ne change rien ici.
abstract interface class NotificationRepository {
  Stream<NotificationPreferences> watchPreferences(String userId);

  AsyncResult<void> savePreferences({
    required String userId,
    required NotificationPreferences preferences,
  });

  /// Fait l’upsert du document d’appareil de cette installation avec le jeton
  /// FCM [token]. Idempotent : appelé à chaque connexion et à chaque
  /// rafraîchissement de jeton.
  AsyncResult<void> registerDevice({
    required String userId,
    required String token,
    required String platform,
  });

  /// Les plus récentes d’abord, en nombre borné, entrées expirées exclues.
  Stream<List<AppNotification>> watchNotifications(String userId);

  AsyncResult<void> markRead({
    required String userId,
    required String notificationId,
  });

  /// Marque comme lues toutes les notifications non lues, y compris les
  /// entrées plus anciennes que le fil borné.
  AsyncResult<void> markAllRead({required String userId});

  AsyncResult<void> deleteNotification({
    required String userId,
    required String notificationId,
  });
}
